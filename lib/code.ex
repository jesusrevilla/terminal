defmodule Terminal.Code do
  use Terminal.Const

  # https://xtermjs.org/docs/api/vtfeatures/
  # xtermjs wont suppot blink #944
  def clear(:all), do: "\ec"
  def clear(:screen), do: "\e[2J"
  def clear(:styles), do: "\e[0m"

  def query(:size), do: "\e[s\e[999;999H\e[6n\e[u"

  # standard required to enable extended
  def mouse(:standard), do: "\e[?1000h"
  def mouse(:extended), do: "\e[?1006h"

  def cursor(:style, :blinking_block), do: "\e[1 q"
  def cursor(:style, :steady_block), do: "\e[2 q"
  def cursor(:style, :blinking_underline), do: "\e[3 q"
  def cursor(:style, :steady_underline), do: "\e[4 q"
  def cursor(:style, :blinking_bar), do: "\e[5 q"
  def cursor(:style, :steady_bar), do: "\e[6 q"
  def cursor(column, line), do: "\e[#{line + 1};#{column + 1}H"

  def show(:cursor), do: "\e[?25h"
  def hide(:cursor), do: "\e[?25l"

  # bright colors are shifted by 8 but frame chars wont show in bblack
  def color(:fgcolor, name), do: "\e[38;5;#{rem(color_id(name), 16)}m"
  def color(:bgcolor, name), do: "\e[48;5;#{rem(color_id(name), 8)}m"

  def set(:bold), do: "\e[1m"
  def set(:dimmed), do: "\e[2m"
  def set(:italic), do: "\e[3m"
  def set(:underline), do: "\e[4m"
  def set(:inverse), do: "\e[7m"
  def set(:crossed), do: "\e[9m"
  def set(_), do: ""

  # normal reset both bold and dimmed
  def reset(:normal), do: "\e[22m"
  def reset(:italic), do: "\e[23m"
  def reset(:underline), do: "\e[24m"
  def reset(:inverse), do: "\e[27m"
  def reset(:crossed), do: "\e[29m"
  def reset(_), do: ""

  def append(buffer, data) do
    buffer = buffer <> data
    scan(buffer, [])
  end

  @resize ~r/^\e\[(\d+);(\d+)R/
  @mouse ~r/^\e\[M(.)(.)(.)/
  @mouse_down ~r/^\e\[<(\d+);(\d+);(\d+)M/
  @mouse_up ~r/^\e\[<(\d+);(\d+);(\d+)m/

  # thinkpad/corsair usb us keyboard
  @escapes [
    {"\e[[A", :f1},
    {"\e[[B", :f2},
    {"\e[[C", :f3},
    {"\e[[D", :f4},
    {"\e[[E", :f5},
    {"\e[17~", :f6},
    {"\e[18~", :f7},
    {"\e[19~", :f8},
    {"\e[20~", :f9},
    {"\e[21~", :f10},
    {"\e[23~", :f11},
    {"\e[24~", :f12},
    {"\e[H", :home},
    {"\e[2~", :insert},
    {"\e[3~", :delete},
    {"\e[F", :end},
    {"\e[5~", :page_up},
    {"\e[6~", :page_down},
    {"\e[A", :arrow_up},
    {"\e[B", :arrow_down},
    {"\e[C", :arrow_right},
    {"\e[D", :arrow_left}
  ]

  @singles [
    {"\d", {@fun, :backspace}},
    {<<0>>, {@ctl, "2"}},
    {<<28>>, {@ctl, "4"}},
    {<<29>>, {@ctl, "5"}},
    {<<30>>, {@ctl, "6"}},
    {<<31>>, {@ctl, "7"}},
    {<<17>>, {@ctl, "q"}},
    {<<23>>, {@ctl, "w"}},
    {<<5>>, {@ctl, "e"}},
    {<<18>>, {@ctl, "r"}},
    {<<20>>, {@ctl, "t"}},
    {<<25>>, {@ctl, "y"}},
    {<<21>>, {@ctl, "u"}},
    {<<15>>, {@ctl, "o"}},
    {<<16>>, {@ctl, "p"}},
    {<<1>>, {@ctl, "a"}},
    {<<19>>, {@ctl, "s"}},
    {<<4>>, {@ctl, "d"}},
    {<<6>>, {@ctl, "f"}},
    {"\a", {@ctl, "g"}},
    {"\b", {@ctl, "h"}},
    {"\v", {@ctl, "k"}},
    {"\f", {@ctl, "l"}},
    {<<26>>, {@ctl, "z"}},
    {<<24>>, {@ctl, "x"}},
    {<<3>>, {@ctl, "c"}},
    {<<22>>, {@ctl, "v"}},
    {<<2>>, {@ctl, "b"}},
    {<<14>>, {@ctl, "n"}}
    # tab -> "\t"
    # prtsc -> <<28>>
    # ctrl_` -> ctrl_2
    # ctrl_1 -> silent
    # ctrl_3 -> \e
    # ctrl_8 -> \d
    # ctrl_9 -> silent
    # ctrl_0 -> silent
    # ctrl_- -> <<31>>
    # ctrl_= -> silent
    # ctrl_back -> \b ctrl_h
    # ctrl_\t -> silent
    # ctrl_m -> \r
    # ctrl_[ -> \e
    # ctrl_] -> ctrl_5
    # ctrl_\ -> :prtsc
    # ctrl_; -> silent
    # ctrl_' -> ctrl_g
    # ctrl_, -> silent
    # ctrl_. -> silent
    # ctrl_/ -> silent
    # ctrl_space -> ctrl_2
    # ctrl_i -> \t
    # ctrl_j -> \n (blocked input at some point)
  ]

  @singles_map @singles |> Enum.into(%{})

  defp scan("", events) do
    {"", Enum.reverse(events)}
  end

  defp scan(buffer, events) do
    {prefix, event} = scan(buffer)
    buffer = tail(buffer, prefix)
    scan(buffer, [event | events])
  end

  defp scan("\e" <> _ = buffer) do
    nil
    |> mouse(buffer, @mouse)
    |> mouse_ex(buffer, @mouse_up, :mouse_up)
    |> mouse_ex(buffer, @mouse_down, :mouse_down)
    |> escapes(buffer)
    |> resize(buffer)
    |> altkey(buffer)
    |> default({"\e", {:key, 0, "\e"}})
  end

  defp scan(<<k>> <> _) do
    singles(<<k>>) |> default({<<k>>, {:key, 0, <<k>>}})
  end

  defp singles(single) do
    case Map.get(@singles_map, single) do
      nil ->
        nil

      code ->
        {flag, key} = code
        {single, {:key, flag, key}}
    end
  end

  defp mouse(nil, buffer, regex) do
    case Regex.run(regex, buffer) do
      [prefix, s, x, y] ->
        [s] = String.to_charlist(s)
        [x] = String.to_charlist(x)
        [y] = String.to_charlist(y)
        {prefix, {:mouse, s - 32, x - 32, y - 32}}

      nil ->
        nil
    end
  end

  defp mouse_ex(nil, buffer, regex, name) do
    case Regex.run(regex, buffer) do
      [prefix, s, x, y] ->
        s = String.to_integer(s)
        x = String.to_integer(x)
        y = String.to_integer(y)
        {prefix, {name, s, x, y}}

      nil ->
        nil
    end
  end

  defp mouse_ex(prev, _, _, _), do: prev

  defp escapes(nil, buffer) do
    Enum.find_value(@escapes, fn {prefix, code} ->
      case String.starts_with?(buffer, prefix) do
        true ->
          {prefix, {:key, @fun, code}}

        false ->
          nil
      end
    end)
  end

  defp escapes(prev, _), do: prev

  defp resize(nil, buffer) do
    case Regex.run(@resize, buffer) do
      [prefix, h, w] ->
        w = String.to_integer(w)
        h = String.to_integer(h)
        {prefix, {:resize, w, h}}

      nil ->
        nil
    end
  end

  defp resize(prev, _), do: prev

  defp altkey(nil, "\e" <> <<k>> <> _) do
    case Map.get(@singles_map, <<k>>) do
      nil ->
        {"\e" <> <<k>>, {:key, @alt, <<k>>}}

      code ->
        {flag, key} = code
        flag = Bitwise.bor(flag, @alt)
        {"\e" <> <<k>>, {:key, flag, key}}
    end
  end

  defp altkey(prev, _), do: prev

  defp default(nil, def), do: def
  defp default(prev, _), do: prev

  defp tail(buffer, prefix) do
    bl = String.length(buffer)
    pl = String.length(prefix)
    String.slice(buffer, pl, bl)
  end
end

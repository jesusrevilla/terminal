#mix run scripts/keymon.exs
#exit with Ctrl+c

alias Terminal.Tty

term = Terminal.Xterm
tty = Teletype.Tty
tty = {tty, []}

tty = Tty.open(tty)
tty = Tty.write!(tty, term.init())
query = term.query(:size)
tty = Tty.write!(tty, query)

Enum.reduce_while(Stream.cycle(0..1), {tty, ""}, fn _, {tty, buffer} ->
  {tty, data} = Tty.read!(tty)
  {buffer, events} = term.append(buffer, data)
  IO.puts "#{inspect(events)}\r"
  case events do
    [{:key, 1, "c"}] -> {:halt, nil}
    _ -> {:cont, {tty, buffer}}
  end
end)

System.cmd "reset", []

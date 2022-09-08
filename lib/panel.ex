defmodule Terminal.Panel do
  @behaviour Terminal.Window
  alias Terminal.Canvas

  def init(opts) do
    theme = Keyword.get(opts, :theme, :default)
    origin = Keyword.get(opts, :origin, {0, 0})
    size = Keyword.get(opts, :size, {0, 0})
    enabled = Keyword.get(opts, :enabled, true)
    visible = Keyword.get(opts, :visible, true)
    focused = Keyword.get(opts, :focused, false)
    findex = Keyword.get(opts, :findex, 0)
    root = Keyword.get(opts, :root, false)

    %{
      root: root,
      index: [],
      children: %{},
      focus: nil,
      focused: focused,
      theme: theme,
      origin: origin,
      visible: visible,
      enabled: enabled,
      findex: findex,
      size: size
    }
  end

  def children(%{index: index, children: children}) do
    for id <- index, reduce: [] do
      list -> [{id, children[id]} | list]
    end
  end

  def children(state, children) do
    {index, children} =
      for {id, child} <- children, reduce: {[], %{}} do
        {index, map} ->
          {[id | index], Map.put(map, id, child)}
      end

    state = Map.put(state, :children, children)
    state = Map.put(state, :index, index)
    focus_update(state)
  end

  def update(state, props) do
    props = Enum.into(props, %{})
    props = Map.drop(props, [:root, :children, :focus, :index, :focused])
    state = Map.merge(state, props)
    focus_update(state)
  end

  def bounds(%{origin: {x, y}, size: {w, h}}), do: {x, y, w, h}
  def bounds(state, {x, y, w, h}), do: state |> Map.put(:size, {w, h}) |> Map.put(:origin, {x, y})
  def focused(state, focused), do: Map.put(state, :focused, focused) |> focus_update
  def focused(%{focused: focused}), do: focused
  def findex(%{findex: findex}), do: findex
  def count(_), do: 0

  def focusable(state) do
    %{
      children: children,
      enabled: enabled,
      visible: visible,
      findex: findex,
      index: index
    } = state

    count =
      for id <- index, reduce: 0 do
        count ->
          mote = Map.get(children, id)

          case mote_focusable(mote) do
            false -> count
            true -> count + 1
          end
      end

    findex >= 0 && visible && enabled && count > 0
  end

  def handle(%{focus: nil} = state, {:key, _, _}), do: {state, nil}

  def handle(%{focus: focus, root: root} = state, {:key, _, _} = event) do
    mote = get_child(state, focus)
    {mote, event} = mote_handle(mote, event)

    case event do
      {:focus, :next} ->
        {first, next} = focus_next(state, focus)

        next =
          case {root, first, next} do
            {_, ^focus, nil} -> nil
            {true, _, nil} -> first
            _ -> next
          end

        case next do
          nil ->
            {put_child(state, focus, mote), {:focus, :next}}

          _ ->
            mote = mote_focused(mote, false)
            state = put_child(state, focus, mote)
            mote = get_child(state, next)
            mote = mote_focused(mote, true)
            state = put_child(state, next, mote)
            {Map.put(state, :focus, next), nil}
        end

      _ ->
        {put_child(state, focus, mote), {focus, event}}
    end
  end

  def handle(state, _event), do: {state, nil}

  def render(%{visible: false}, canvas), do: canvas

  def render(%{index: index, children: children}, canvas) do
    for id <- Enum.reverse(index), reduce: canvas do
      canvas ->
        mote = Map.get(children, id)
        bounds = mote_bounds(mote)
        canvas = Canvas.push(canvas, bounds)
        canvas = mote_render(mote, canvas)
        canvas = Canvas.pop(canvas)
        canvas
    end
  end

  defp focus_next(state, focus) do
    index = focus_list(state)

    case index do
      [] ->
        {nil, nil}

      [first | _] ->
        {next, _} =
          for id <- index, reduce: {nil, false} do
            {nil, true} ->
              {id, true}

            {next, true} ->
              {next, true}

            {_, false} ->
              case id do
                ^focus -> {nil, true}
                _ -> {nil, false}
              end
          end

        {first, next}
    end
  end

  defp focus_list(state) do
    %{index: index} = state
    index = Enum.filter(index, &child_focusable(state, &1))
    index = Enum.reverse(index)
    Enum.sort(index, &focus_compare(state, &1, &2))
  end

  defp focus_compare(state, id1, id2) do
    fi1 = child_findex(state, id1)
    fi2 = child_findex(state, id2)
    fi1 <= fi2
  end

  defp focus_update(state) do
    %{
      visible: visible,
      enabled: enabled,
      focused: focused,
      focus: focus
    } = state

    expected = visible && enabled && focused

    {state, focus} =
      case focus do
        nil ->
          {state, nil}

        _ ->
          case get_child(state, focus) do
            nil ->
              state = Map.put(state, :focus, nil)
              {state, nil}

            mote ->
              focused = mote_focused(mote)
              focusable = mote_focusable(mote)

              case {focusable && expected, focused} do
                {false, false} ->
                  state = Map.put(state, :focus, nil)
                  {state, nil}

                {false, true} ->
                  mote = mote_focused(mote, false)
                  state = put_child(state, focus, mote)
                  state = Map.put(state, :focus, nil)
                  {state, nil}

                {true, false} ->
                  mote = mote_focused(mote, true)
                  state = put_child(state, focus, mote)
                  {state, focus}

                {true, true} ->
                  {state, focus}
              end
          end
      end

    case {expected, focus} do
      {true, nil} ->
        case focus_list(state) do
          [] ->
            state

          [focus | _] ->
            mote = get_child(state, focus)
            mote = mote_focused(mote, true)
            state = put_child(state, focus, mote)
            Map.put(state, :focus, focus)
        end

      _ ->
        state
    end
  end

  defp get_child(state, id), do: get_in(state, [:children, id])
  defp put_child(state, id, child), do: put_in(state, [:children, id], child)
  defp child_focusable(state, id), do: mote_focusable(get_child(state, id))
  defp child_findex(state, id), do: mote_findex(get_child(state, id))
  defp mote_bounds({module, state}), do: module.bounds(state)
  defp mote_findex({module, state}), do: module.findex(state)
  defp mote_focusable({module, state}), do: module.focusable(state)
  defp mote_focused({module, state}), do: module.focused(state)
  defp mote_focused({module, state}, focused), do: {module, module.focused(state, focused)}
  defp mote_render({module, state}, canvas), do: module.render(state, canvas)

  defp mote_handle({module, state}, event) do
    {state, event} = module.handle(state, event)
    {{module, state}, event}
  end
end

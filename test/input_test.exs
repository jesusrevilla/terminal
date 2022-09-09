defmodule InputTest do
  use ExUnit.Case
  alias Terminal.Input

  test "basic input check" do
    initial = Input.init()

    # defaults
    assert initial == %{
             text: "",
             cursor: 0,
             focused: false,
             visible: true,
             enabled: true,
             password: false,
             findex: 0,
             theme: :default,
             size: {0, 1},
             origin: {0, 0},
             on_change: &Input.nop/1
           }

    # panel getters/setters
    assert Input.bounds(%{origin: {1, 2}, size: {3, 4}}) == {1, 2, 3, 4}
    assert Input.focusable(%{initial | enabled: false}) == false
    assert Input.focusable(%{initial | visible: false}) == false
    assert Input.focusable(%{initial | on_change: nil}) == false
    assert Input.focusable(%{initial | findex: -1}) == false
    assert Input.focused(%{focused: false}) == false
    assert Input.focused(%{focused: true}) == true
    assert Input.focused(initial, true) == %{initial | focused: true}
    assert Input.findex(%{findex: 0}) == 0
    assert Input.children(:state) == []
    assert Input.children(:state, []) == :state

    # react update
    on_change = fn value -> value end
    assert Input.update(initial, focused: true) == initial
    assert Input.update(initial, cursor: -1) == initial
    assert Input.update(initial, visible: false) == %{initial | visible: false}
    assert Input.update(initial, enabled: false) == %{initial | enabled: false}
    assert Input.update(initial, password: true) == %{initial | password: true}
    assert Input.update(initial, findex: 1) == %{initial | findex: 1}
    assert Input.update(initial, theme: :theme) == %{initial | theme: :theme}
    assert Input.update(initial, origin: {1, 2}) == %{initial | origin: {1, 2}}
    assert Input.update(initial, size: {2, 3}) == %{initial | size: {2, 3}}
    assert Input.update(initial, on_change: on_change) == %{initial | on_change: on_change}

    # reset of calculated props
    assert Input.update(initial, text: "text") == %{initial | text: "text", cursor: 4}

    assert Input.handle(%{}, {:key, nil, "\t"}) == {%{}, {:focus, :next}}
    assert Input.handle(%{}, {:key, nil, "\r"}) == {%{}, {:focus, :next}}

    # ignore keyboard events
    assert Input.handle(initial, {:key, nil, :arrow_left}) == {initial, nil}
    assert Input.handle(initial, {:key, nil, :arrow_right}) == {initial, nil}
    assert Input.handle(initial, {:key, nil, :delete}) == {initial, nil}
    assert Input.handle(initial, {:key, nil, :backspace}) == {initial, nil}
    assert Input.handle(initial, {:key, nil, :home}) == {initial, nil}
    assert Input.handle(initial, {:key, nil, :end}) == {initial, nil}
    assert Input.handle(initial, {:key, 0, "a"}) == {initial, nil}

    assert Input.handle(%{initial | size: {10, 1}, text: "a"}, {:key, 0, :backspace}) ==
             {%{initial | size: {10, 1}, text: "a"}, nil}

    assert Input.handle(%{initial | size: {10, 1}, text: "a", cursor: 1}, {:key, 0, :delete}) ==
             {%{initial | size: {10, 1}, text: "a", cursor: 1}, nil}

    # handle text input
    assert Input.handle(%{initial | size: {10, 1}}, {:key, 0, "a"}) ==
             {%{initial | size: {10, 1}, text: "a", cursor: 1}, {:text, "a"}}

    assert Input.handle(%{initial | size: {10, 1}, text: "a", cursor: 1}, {:key, 0, "b"}) ==
             {%{initial | size: {10, 1}, text: "ab", cursor: 2}, {:text, "ab"}}

    assert Input.handle(%{initial | size: {10, 1}, text: "a", cursor: 0}, {:key, 0, "b"}) ==
             {%{initial | size: {10, 1}, text: "ba", cursor: 1}, {:text, "ba"}}

    assert Input.handle(%{initial | size: {10, 1}, text: "ab", cursor: 1}, {:key, 0, "c"}) ==
             {%{initial | size: {10, 1}, text: "acb", cursor: 2}, {:text, "acb"}}

    assert Input.handle(%{initial | size: {10, 1}, text: "abc", cursor: 1}, {:key, 0, :delete}) ==
             {%{initial | size: {10, 1}, text: "ac", cursor: 1}, {:text, "ac"}}

    assert Input.handle(%{initial | size: {10, 1}, text: "abc", cursor: 1}, {:key, 0, :backspace}) ==
             {%{initial | size: {10, 1}, text: "bc", cursor: 0}, {:text, "bc"}}
  end
end

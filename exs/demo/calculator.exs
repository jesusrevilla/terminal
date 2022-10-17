defmodule Terminal.Demo.Calculator do
  use Terminal.React

  def calculator(react, %{origin: origin, size: size}) do
    {result, set_result} = use_state(react, :result, "0")
    {operation, set_operation} = use_state(react, :operation, "")
    {operator, set_operator} = use_state(react, :operator, "")
    
    {state, set_state} = use_state(react, :state, :idle)
    {mode, set_mode} = use_state(react, :mode, :integer)

    on_number = fn n ->
      case state do
        :error        -> :not_ok
        :idle         -> set_result.(n)
                         set_state.(:input)                       
        :input        -> set_result.(result <> n)
        :wait_operand -> set_result.(result <> n)
                         set_state.(:input)                     
      end
    end

    on_clear = fn ->
      set_result.("0")
      set_mode.(:integer)
      set_state.(:idle)
      set_operation.("")
      set_operator.("")
    end

    on_point = fn ->
      case {state, mode} do
        {:error, _}        -> :not_ok
        {_, :float}        -> :not_ok
        {:wait_operand, _} -> :not_ok
        {:idle, :integer}  -> set_result.("0.")
                              set_mode.(:float)
                              set_state.(:wait_operand)
        {:input, :integer} -> set_result.("#{result}.")
                              set_mode.(:float)
                              set_state.(:wait_operand)
      end      
    end

    on_negative = fn ->
      case state do
        :error -> :not_ok
        :wait_operand -> :not_ok
        _ -> {res, _} = Code.eval_string "#{result} * -1"
                  set_result.(res)
      end
    end
    
    on_operator = fn op ->
      case state do
        :error        ->  :not_ok
        :wait_operand ->  :not_ok
                          _ -> {res, _} = Code.eval_string(result)
                          set_operation.("#{res} #{op} ")
                          set_operator.(op)
                          set_state.(:idle)
                          set_mode.(:integer)                  
      end
    end

    on_equal = fn ->
      case state do
        :error -> :not_ok
        :idle  -> :not_ok
        :wait_operand -> :not_ok
        :input -> try do
                    {res, _} = Code.eval_string "#{operation}#{result}"
                    set_result.(res)
                    set_operation.(res)
                    set_state.(:idle)
                    set_mode.(:integer)                               
                  rescue
                    e in ArithmeticError -> set_result.("Divide by zero error")
                                            set_state.(:error)
                  end 
      end
    end      

    # buttons disabled on invalid range to show autorefocus
    markup :main, Panel, origin: origin, size: size do
      markup(:label, Label, origin: {0, 1}, size: {29, 1}, text: String.pad_leading("#{result}", 29, " "))

      markup(:seven, Button,
        origin: {0, 3},
        size: {5, 1},
        text: "7",
        enabled: true,
        on_click: fn -> on_number.("7") end
      )

      markup(:eight, Button,
        origin: {6, 3},
        size: {5, 1},
        text: "8",
        enabled: true,
        on_click: fn -> on_number.("8") end
      )

      markup(:nine, Button,
        origin: {12, 3},
        size: {5, 1},
        text: "9",
        enabled: true,
        on_click:  fn -> on_number.("9") end
      )  

      markup(:plusminus, Button,
        origin: {18, 3},
        size: {5, 1},
        text: "+/-",
        enabled: true,
        on_click: on_negative
      ) 

      markup(:divide, Button,
        origin: {24, 3},
        size: {5, 1},
        text: "/",
        enabled: true,
        on_click: fn -> on_operator.("/") end
      )         

      markup(:four, Button,
        origin: {0, 5},
        size: {5, 1},
        text: "4",
        enabled: true,
        on_click: fn -> on_number.("4") end
      )  

      markup(:five, Button,
        origin: {6, 5},
        size: {5, 1},
        text: "5",
        enabled: true,
        on_click: fn -> on_number.("5") end
      )  

      markup(:six, Button,
        origin: {12, 5},
        size: {5, 1},
        text: "6",
        enabled: true,
        on_click: fn -> on_number.("6") end
      )  

      markup(:clear, Button,
        origin: {18, 5},
        size: {5, 1},
        text: "CLR",
        enabled: true,
        on_click: on_clear
      ) 


      markup(:times, Button,
        origin: {24, 5},
        size: {5, 1},
        text: "*",
        enabled: true,
        on_click: fn -> on_operator.("*") end
      ) 

      markup(:one, Button,
        origin: {0, 7},
        size: {5, 1},
        text: "1",
        enabled: true,
        on_click: fn -> on_number.("1") end
      )  
      
      markup(:two, Button,
        origin: {6, 7},
        size: {5, 1},
        text: "2",
        enabled: true,
        on_click: fn -> on_number.("2") end
      )  

      markup(:three, Button,
        origin: {12, 7},
        size: {5, 1},
        text: "3",
        enabled: true,
        on_click: fn -> on_number.("3") end
      )     

      markup(:equal, Button,
        origin: {18, 7},
        size: {5, 3},
        text: "=",
        enabled: true,
        on_click: on_equal
      )                   

      markup(:plus, Button,
        origin: {24, 7},
        size: {5, 1},
        text: "+",
        enabled: true,
        on_click: fn -> on_operator.("+") end
      )     

      markup(:zero, Button,
        origin: {0, 9},
        size: {11, 1},
        text: "0",
        enabled: true,
        on_click: fn -> on_number.("0") end
      ) 

      markup(:point, Button,
        origin: {12, 9},
        size: {5, 1},
        text: ".",
        enabled: true,
        on_click: on_point
      )              

      markup(:minus, Button,
        origin: {24, 9},
        size: {5, 1},
        text: "-",
        enabled: true,
        on_click: fn -> on_operator.("-") end
      )

                                  
    end
  end
end

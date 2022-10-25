defmodule Terminal.Demo.Calculator do
  use Terminal.React

  def calculator(react, %{origin: origin, size: size}) do
    {result, set_result} = use_state(react, :result, "0")
    {operation, set_operation} = use_state(react, :operation, "")
    
    on_key = fn key ->
      set_operation.(operation <> key)
    end

    on_clear = fn ->
      set_result.("0")
      set_operation.("")
    end

    on_negative = fn ->
      case String.starts_with?(operation, "-") do
        true -> {_, res} = String.split_at(operation, 1)
                set_operation.(res)
        false -> set_operation.("-" <> operation)
      end
    end
    
    on_equal = fn ->
      try do
        {res, _} = Code.eval_string "#{operation}"
        set_result.(res)                            
      rescue
        _e in ArithmeticError -> set_result.("Divide by zero error")
        _e in TokenMissingError -> set_result.("Token missing error")
        _e in SyntaxError ->     set_result.("Syntax error")
      end 
    end      

    on_back_space = fn ->
      {res, _} = String.split_at(operation, -1)
      set_operation.(res)
    end 

    # buttons disabled on invalid range to show autorefocus
    markup :main, Panel, origin: origin, size: size do
      markup(:label, Label, origin: {0, 1}, size: {29, 1}, text: String.pad_leading("#{result}", 29, " "))
      markup(:operation, Label, origin: {0, 0}, size: {29, 1}, text: String.pad_leading("#{operation}", 29, " "))

      markup(:seven, Button,
        origin: {0, 3},
        size: {5, 1},
        text: "7",
        on_click: fn -> on_key.("7") end
      )

      markup(:eight, Button,
        origin: {6, 3},
        size: {5, 1},
        text: "8",
        on_click: fn -> on_key.("8") end
      )

      markup(:nine, Button,
        origin: {12, 3},
        size: {5, 1},
        text: "9",
        on_click:  fn -> on_key.("9") end
      )  

      markup(:plusminus, Button,
        origin: {18, 3},
        size: {5, 1},
        text: "+/-",
        on_click: on_negative
      ) 

      markup(:divide, Button,
        origin: {24, 3},
        size: {5, 1},
        text: "/",
        on_click: fn -> on_key.("/") end
      )         

      markup(:four, Button,
        origin: {0, 5},
        size: {5, 1},
        text: "4",
        on_click: fn -> on_key.("4") end
      )  

      markup(:five, Button,
        origin: {6, 5},
        size: {5, 1},
        text: "5",
        on_click: fn -> on_key.("5") end
      )  

      markup(:six, Button,
        origin: {12, 5},
        size: {5, 1},
        text: "6",
        on_click: fn -> on_key.("6") end
      )  

      markup(:clear, Button,
        origin: {18, 5},
        size: {5, 1},
        text: "CLR",
        on_click: on_clear
      ) 


      markup(:times, Button,
        origin: {24, 5},
        size: {5, 1},
        text: "*",
        on_click: fn -> on_key.("*") end
      ) 

      markup(:one, Button,
        origin: {0, 7},
        size: {5, 1},
        text: "1",
        on_click: fn -> on_key.("1") end
      )  
      
      markup(:two, Button,
        origin: {6, 7},
        size: {5, 1},
        text: "2",
        on_click: fn -> on_key.("2") end
      )  

      markup(:three, Button,
        origin: {12, 7},
        size: {5, 1},
        text: "3",
        on_click: fn -> on_key.("3") end
      )     

      markup(:equal, Button,
        origin: {18, 7},
        size: {5, 3},
        text: "=",
        on_click: on_equal
      )                   

      markup(:plus, Button,
        origin: {24, 7},
        size: {5, 1},
        text: "+",
        on_click: fn -> on_key.("+") end
      )     

      markup(:zero, Button,
        origin: {0, 9},
        size: {11, 1},
        text: "0",
        on_click: fn -> on_key.("0") end
      ) 

      markup(:point, Button,
        origin: {12, 9},
        size: {5, 1},
        text: ".",
        on_click: fn -> on_key.(".") end
      )  

      markup(:backspace, Button,
        origin: {18, 9},
        size: {5, 1},
        text: "BKS",
        on_click: on_back_space
      ) 

      markup(:minus, Button,
        origin: {24, 9},
        size: {5, 1},
        text: "-",
        on_click: fn -> on_key.("-") end
      )
                                 
    end
  end
end

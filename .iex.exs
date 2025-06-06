defmodule IexHelpers do
  def blanks(n \\ 20) do
    1..n
    |> Enum.each(fn _ ->
      IO.puts("")
    end)
  end
end

alias IexHelpers, as: Ih
import IexHelpers

## project specific

alias Ethers, as: E
alias Ethers.Utils, as: Util
alias Ethers.Transaction, as: Tx
alias Ethers.Types

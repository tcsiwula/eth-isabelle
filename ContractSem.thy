(*
   Copyright 2016 Yoichi Hirai

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
*)

section "A Contract Centric View of the EVM"

text {* Here is a presentation of the Ethereum Virtual Machine (EVM) in a form
suitable for formal verification of a single account.  *}

theory ContractSem

imports Main "~~/src/HOL/Word/Word" "./ContractEnv" "./Instructions" "./KEC" "./lem/Evm"

begin

declare venv_advance_pc_def [simp]
declare venv_next_instruction_def [simp]
declare call_def [simp]

subsection "Utility Functions"

text {* The following function is an if-sentence, but with some strict control
over the evaluation order.  Neither the then-clause nor the else-clause
is simplified during proofs.  This prevents the automatic simplifier from
computing the results of both the then-clause and the else-clause.
*}

text {* When the if-condition is known to be True, the simplifier can
proceed into the then-clause.  The \textit{simp} attribute encourages the simplifier
to use this equation from left to right whenever applicable.  *}

lemma strict_if_True [simp] :
"strict_if True a b = a True"
apply(simp add: strict_if_def)
done

text {* When the if-condition is known to be False, the simplifier
can proceed into the else-clause. *}

lemma strict_if_False [simp] :
"strict_if False a b = b True"
apply(simp add: strict_if_def)
done

text {* When the if-condition is not known to be either True or False,
the simplifier is allowed to perform computation on the if-condition.
The \textit{cong} attribute tells the simplifier to try to rewrite the
left hand side of the conclusion, using the assumption.
*}

lemma strict_if_cong [cong] :
"b0 = b1 \<Longrightarrow> strict_if b0 x y = strict_if b1 x y"
apply(auto)
done

subsection "The Interaction between the Contract and the World"

text {*In this development, the EVM execution is seen as an interaction between a single contract
invocation
and the rest of the world.  The world can call into the contract.  The contract can reply by just
finishing or failing, but it can also call an account\footnote{This might be the same account as our
invocation, but still the deeper calls is part of the world.}.  When our contract execution calls an account,
this is seen as an action towards the world, because the world then has to decide the
result of this call.  The world can say that the call finished successfully or exceptionally.
The world can also say that the call resulted in a reentrancy.  In other words,
the world can call the contract again and change the storage and the balance of our contract.
The whole process is captured as a game between
the world and the contract. *}

subsubsection "The Contract's Moves"

text {* After being invoked, the contract can respond by calling an account, creating (or deploying)
a smart contract, destroying itself, returning, or failing.  When the contract calls an account,
the contract provides the following information.*}

text {* When our contract deploys a smart contract, our contract should provide the following
information. *}

text {* The contract's moves are summarized as follows. *}

subsection "Program Representation"

text "For performance reasons, the instructions are stored in an AVL tree that allows
looking up instructions from the program counters."

text {* The empty program is easy to define. *}

declare empty_program_def [simp]

subsection "Translating an Instruction List into a Program"

subsubsection {* Storing annotations in a program in a mapping *}

text {* Annotations are stored in a mapping that maps positions into lists of annotations.
The rationale for this data structure is that a single position might contain multiple annotations.
Here is a function that inserts an annotation
at a specified position. *}

declare prepend_annotation_def [simp]

declare program_annotation_of_lst.simps [simp]

subsubsection {* Translating a list of instructions into a program *}

text {* The results of the above translations are packed together in a record. *}
text {* For efficiency reasons, the program content is going to be packed as
an AVL tree, but this particular encoding is not part of the Lem definition.
So such encoders are parametrised here.*}

declare program_of_lst_def [simp]

subsection {* Program as a Byte Sequence *}

text {* For CODECOPY instruction, the program must be seen as a byte-indexed read-only memory. *}
text {* Such a memory is here implemented by a lookup on an AVL tree.*}

declare program_as_memory_def [simp]
   
subsection {* Execution Environments *}

text "I model an instruction as a function that takes environments and modifies some parts of them."

text "The execution of an EVM program happens in a block, and the following information about
the block should be available."

text {* The variable environment contains information that is relatively volatile. *}

text {* The constant environment contains information that is rather stable. *}

subsection {* The Result of an Instruction *}

text {* The result of program execution is microscopically defined by results of instruction
executions.  The execution of a single instruction can result in the following cases: *}

text {* When the contract fails, the result of the instruction always looks like this: *}
    
declare instruction_failure_result_def [simp]

text {* When the contract returns, the result of the instruction always looks like this: *}
  
declare instruction_return_result_def [simp]

subsection {* Useful Functions for Defining EVM Operations *}

text {* Currently the GAS instruction is modelled to return random numbers.
The random number is not known to be of any value.
However, the value is not unknown enough in this formalization because
the value is only dependent on the variable environment (which does not
keep track of the remaining gas).  This is not a problem as long as
we are analyzing a single invocation of a loopless contract, but
gas accounting is a planned feature.
*}

text {* This $M$ function is defined at the end of H.1.\,in the yellow paper.
This function is useful for updating the memory usage counter. *}

declare M_def [simp]

text {* Updating a balance of a single account:  *}
declare update_balance_def [simp]

text {* Popping stack elements: *}
declare venv_pop_stack.simps [simp]

text {* Peeking the topmost element of the stack: *}
declare venv_stack_top_def [simp]

text {* Updating the storage at an index: *}

declare venv_update_storage_def [simp]
  
text {* No-op, which just advances the program counter: *}
declare stack_0_0_op_def [simp]

text {* A general pattern of operations that pushes one element onto the stack:  *}
declare stack_0_1_op_def [simp]

text {* A general pattern of operations that transforms the topmost element of the stack: *}
declare stack_1_1_op_def [simp]

text {* A general pattern of operations that consume one word and produce two rwords: *}
declare stack_1_2_op_def [simp]

text {* A general pattern of operations that take two words and produce one word: *}
declare stack_2_1_op_def [simp]

text {* A general pattern of operations that take three words and produce one word: *}
declare stack_3_1_op_def [simp]

subsection {* Definition of EVM Operations *}

text "SSTORE changes the storage so it does not fit into any of the patterns defined above."
declare sstore_def [simp]

text "For interpreting the annotations, I first need to construct the annotation environment
out of the current execution environments.  When I try to remove this step, I face some
circular definitions of data types."
declare build_aenv_def [simp]

text "In reality, EVM programs do not contain annotations so annotations never cause failures.
However, during the verification, I want to catch annotation failures.  When the annotation
evaluates to False, the execution stops and results in @{term InstructionAnnotationFailure}."
    
text "The JUMP instruction has the following meaning.  When it cannot find the JUMPDEST instruction
at the destination, the execution fails."
declare jump_def [simp]

text {* This function is a reminiscent of my struggle with the Isabelle/HOL simplifier.
The second argument has no meaning but to control the Isabelle/HOL simplifier.
*}

text {* When the second argument is already @{term True}, the simplification can continue.
Otherwise, the Isabelle/HOL simplifier is not allowed to expand the definition of
@{term blockedInstructionContinue}. *}
lemma unblockInstructionContinue [simp] :
"blockedInstructionContinue v True = InstructionContinue v"
apply(simp add: blockedInstructionContinue_def)
done

text {* This is another reminiscent of my struggle against the Isabelle/HOL simplifier.
Again, the simplifier is not allowed to expand the definition unless the second argument
is known to be @{term True}.*}

lemma unblock_jump [simp]:
"blocked_jump v c True = jump v c"
apply(simp add: blocked_jump_def)
done

text {* The JUMPI instruction is implemented using the JUMP instruction. *}

declare jumpi_def [simp]

text {* Looking up the call data size takes this work: *}
declare datasize_def [simp]

text {* Looking up a word from a list of bytes: *}
declare read_word_from_bytes_def [simp]

text {* Looking up a word from the call data: *}
declare cut_data_def [simp]

text {* Looking up a number of bytes from the memory: *}
fun cut_memory :: "w256 \<Rightarrow> nat \<Rightarrow> (w256 \<Rightarrow> byte) \<Rightarrow> byte list"
where
"cut_memory idx 0 memory = []" |
"cut_memory idx (Suc n) memory =
  memory idx # cut_memory (idx + 1) n memory"
  
declare cut_memory.simps [simp]

text {* CALL instruction results in @{term ContractCall} action when there are enough stack elements
        (and gas, when we introduce the gas accounting). *}

text {* DELEGATECALL is slightly different. *}

declare delegatecall_def [simp]

text {* CALLCODE is another variant. *}

declare callcode_def [simp]

text "CREATE is also similar because the instruction causes execution on another account."

declare create_def [simp]

text "RETURN is modeled like this:"
declare ret_def [simp]

text "STOP is simpler than RETURN:"
declare stop_def [simp]

text "POP removes the topmost element of the stack:"
declare pop_def [simp]

text "A utility function for storing a list of bytes in the memory:"
fun store_byte_list_memory :: "w256 \<Rightarrow> byte list \<Rightarrow> memory \<Rightarrow> memory"
where
  "store_byte_list_memory _ [] orig = orig"
| "store_byte_list_memory pos (h # t) orig =
     store_byte_list_memory (pos + 1) t (orig(pos := h))"

declare store_byte_list_memory.simps [simp]

text "Using the function above, it is straightforward to store a byte in the memory."
declare store_word_memory_def [simp]

text "MSTORE writes one word to the memory:"

declare mstore_def [simp]

text "MLOAD reads one word from the memory:"

declare mload_def [simp]

text "MSTORE8 writes one byte to the memory:"

declare mstore8_def [simp]

text "For CALLDATACOPY, I need to look at the caller's data as memory."

declare input_as_memory_def [simp]

text "CALLDATACOPY:"
declare calldatacopy_def [simp]

text "CODECOPY copies a region of the currently running code to the memory:"
declare codecopy_def [simp]

text "EXTCODECOPY copies a region of the code of an arbitrary account.:"
declare extcodecopy_def [simp]

text "PC instruction could be implemented by @{term stack_0_1_op}:"
declare pc_def [simp]

text "Logging is currently no-op, until some property about event logging is wanted."
definition log :: "nat \<Rightarrow> variable_env \<Rightarrow> constant_env \<Rightarrow> instruction_result"
where
"log n v c =
   InstructionContinue (venv_advance_pc c
     (venv_pop_stack (Suc (Suc n)) v))"
     
declare log_def [simp]

text "For SWAP operations, I first define a swap operations on lists."
definition list_swap :: "nat \<Rightarrow> 'a list \<Rightarrow> 'a list option"
where
"list_swap n lst =
  (if length lst < n + 1 then None else
  Some (List.concat [[lst ! n], take (n - 1) (drop 1 lst) , [lst ! 0], drop (1 + n) lst]))"
  
declare list_swap_def [simp]

text "For testing, I prove some lemmata:"

lemma "list_swap 1 [0, 1] = Some [1, 0]"
apply(auto)
done

lemma "list_swap 2 [0, 1] = None"
apply(auto)
done

lemma "list_swap 2 [0, 1, 2] = Some [2, 1, 0]"
apply(auto)
done

lemma "list_swap 3 [0, 1, 2, 3] = Some [3, 1, 2, 0]"
apply(auto)
done

lemma"list_swap 1 [0, 1, 2, 3] = Some [1, 0, 2, 3]"
apply(auto)
done

text "Using this, I can specify the SWAP operations:"

declare swap_def [simp]

text {* SHA3 instruciton in the EVM is actually reaak 256.
In this development, Keccak256 computation is defined in KEC.thy.
*}
definition sha3 :: "variable_env \<Rightarrow> constant_env \<Rightarrow> instruction_result"
where
"sha3 v c \<equiv>
  (case venv_stack v of
    start # len # rest \<Rightarrow>
      InstructionContinue (
        venv_advance_pc c v\<lparr> venv_stack := keccack
                                         (cut_memory start (unat len) (venv_memory v))
                                        # rest
                        , venv_memory_usage := M (venv_memory_usage v) start len
                        \<rparr>)
  | _ \<Rightarrow> instruction_failure_result v)"

declare sha3_def [simp]

declare general_dup_def [simp]

text "The SUICIDE instruction involves value transfer."
definition suicide :: "variable_env \<Rightarrow> constant_env \<Rightarrow> instruction_result"
where
"suicide v c =
  (case venv_stack v of 
     dst # _ \<Rightarrow>
       let new_balance = (venv_balance v)(cenv_this c := 0,
         ucast dst := venv_balance v (cenv_this c) + (venv_balance v (ucast dst))) in
       InstructionToWorld ContractSuicide (venv_storage v) new_balance None
    | _ \<Rightarrow> instruction_failure_result v)"

declare suicide_def [simp]

text "Finally, using the above definitions, I can define a function that operates an instruction
on the execution environments."

lemma "Word.word_rcat [(0x01 :: byte), 0x02] = (0x0102 :: w256)"
apply(simp add: word_rcat_def)
apply(simp add: bin_rcat_def)
apply(simp add: bin_cat_def)
done
    
declare instruction_sem.simps [simp]

subsection {* Programs' Answer to the World *}

text "Execution of a program is harder than that of instructions.  The biggest difficulty is that
the length of the execution is arbitrary.  In Isabelle/HOL all functions must terminate, so I need
to prove the termination of program execution.  In priciple, I could have used gas, but I was
lazy to model gas at that moment, so I introduced an artificial step counter.  When I prove theorems
about smart contracts, the theorems are of the form ``for any value of the initial step counter,
this and that never happen.''"

text "Since our program struct contains a list of annotations for each program position,
I have a function that checks all annotations at a particular program position:"  

declare check_annotations_def [simp]

   
text {* The program execution takes two counters.
One counter is decremented for each instruction.
The other counter is decremented when a backward-jump happens.
This setup allows an easy termination proof.
Also, during the proofs, I can do case analysis on the number of backwad jumps
rather than the number of instructions.
*}

declare program_sem.simps [simp]

text {* The following lemma is just for controlling the Isabelle/HOL simplifier. *}

lemma unblock_program_sem [simp] : "blocked_program_sem v c l p True = program_sem v c l p"
apply(simp add: blocked_program_sem.psimps)
done

definition program_sem_blocked :: "variable_env \<Rightarrow> constant_env \<Rightarrow> int \<Rightarrow> nat \<Rightarrow> bool \<Rightarrow> program_result"
where
"program_sem_blocked v c internal external _ = program_sem v c internal external"

lemma program_sem_unblock :
"program_sem_blocked v c internal external True = program_sem v c internal external"
apply(simp add: program_sem_blocked_def)
done

subsection {* Account's State *}

text {* In the bigger picture, a contract invocation changes accounts' states.
An account has a storage, a piece of code and a balance.
Since I am interested in account states in the middle of a transaction, I also need to
keep track of the ongoing executions of a single account.  Also I need to keep track of
a flag indicating if the account has already marked for erasure.
*}

subsection {* Environment Construction before EVM Execution *}

text {* I need to connect the account state and the program execution environments.
First I construct program execution environments from an account state.
*}

text {* Given an account state and a call from the world
we can judge if a variable environment is possible or not.
The block state is arbitrary.  This means we verify properties that hold
on whatever block numbers and whatever difficulties and so on.
The origin of the transaction is also considered arbitrary.
*}
inductive build_venv_called :: "account_state \<Rightarrow> call_env \<Rightarrow> variable_env \<Rightarrow> bool"
where
venv_called:
  "bal (account_address a) =
   (* natural increase is taken care of in RelationalSem.thy *)
       account_balance a \<Longrightarrow>
   build_venv_called a env
   \<lparr> (* The stack is initialized for every invocation *)
     venv_stack = []

     (* The memory is also initialized for every invocation *)
   , venv_memory = empty_memory
   
     (* The memory usage is initialized. *)
   , venv_memory_usage = 0
   
     (* The storage is taken from the account state *)
   , venv_storage = account_storage a

     (* The program counter is initialized to zero *)
   , venv_pc = 0 

     (* The balance is arbitrary, except that the balance of this account *)
     (* is as specified in the account state plus the sent amount. *)
   , venv_balance = bal(account_address a := bal (account_address a) + callenv_value env) 

   (* the caller is specified by the world *)
   , venv_caller = callenv_caller env

   (* the sent value is specified by the world *)
   , venv_value_sent = callenv_value env 

   (* the sent data is specified by the world *)
   , venv_data_sent = callenv_data env 

   (* the snapshot of the storage is remembered in case of failure *)
   , venv_storage_at_call = account_storage a 

   (* the snapshot of the balance is remembered in case of failure *)
   , venv_balance_at_call = bal 

   (* the origin of the transaction is arbitrarily chosen *)
   , venv_origin = origin 

   (* the codes of the external programs are arbitrary. *)
   , venv_ext_program = ext 

   (* the block information is chosen arbitrarily. *)
   , venv_block = block 
   \<rparr>
   "

declare build_venv_called.simps [simp]

text {* Similarly we can construct the constant environment.
Construction of the constant environment is much simpler than that of 
a variable environment. 
*}

declare build_cenv_def [simp]

text "Next we turn to the case where the world returns back to the account after the account has
called an account.  In this case, the account should contain one ongoing execution that is waiting
for a call to return."

text "An instruction is ``call-like'' when it calls an account and waits for it to return."

declare is_call_like_def [simp]


text {* When an account returns to our contract, the variable environment is
recovered from the stack of the ongoing calls.  However, due to reentrancy,
the balance and the storage of our contract might have changed.  So the
balance and the storage are taken from the account state provided.
Moreover, the balance of
our contract might increase because some other contracts might have destroyed themselves,
transferring value to our contract.*}

function put_return_values :: "memory \<Rightarrow> byte list \<Rightarrow> int \<Rightarrow> int \<Rightarrow> memory"
where
  "s \<le> 0 \<Longrightarrow> put_return_values orig _ _ s = orig"
| "s > 0 \<Longrightarrow> put_return_values orig [] _ s = orig"
| "s > 0 \<Longrightarrow> put_return_values orig (h # t) b s =
             put_return_values (orig(word_of_int b := h)) t (b + 1) (s - 1)"
apply(auto)
apply(case_tac "b \<le> 0"; auto?)
apply(case_tac aa; auto)
done

text {* When the control flow comes back to an account state
in the form of a return from an account,
we build a variable environment as follows.
The process is not deterministic because
the balance of our contract might have
arbitrarily increased.
*}

inductive build_venv_returned ::
"account_state \<Rightarrow> return_result \<Rightarrow> variable_env \<Rightarrow> bool"
where
venv_returned:
"  is_call_like ((program_content a_code) (v_pc - 1)) \<Longrightarrow>
   new_bal \<ge> a_bal \<Longrightarrow> (* the balance might have increased *)
   build_venv_returned

     (* here is the first argument *)
     \<lparr> account_address = a_addr (* all elements are spelled out for performance *)
     , account_storage = a_storage
     , account_code = a_code
     , account_balance = a_bal
     , account_ongoing_calls =
         (\<lparr> venv_stack = v_stack
         , venv_memory = v_memory
         , venv_memory_usage = v_memory_usage
         , venv_storage = v_storage
         , venv_pc = v_pc
         , venv_balance = v_balance
         , venv_caller = v_caller
         , venv_value_sent = v_value
         , venv_data_sent = v_data
         , venv_storage_at_call = v_init_storage
         , venv_balance_at_call = v_init_balance
         , venv_origin = v_origin
         , venv_ext_program = v_ext_program
         , venv_block = v_block
         \<rparr>, mem_start, mem_size) # _
     , account_killed = _
     \<rparr>
     
     (* here is the second argument *)
     r
     
     (* here is the third argument *)
     (\<lparr>  venv_stack = 1 # v_stack (* 1 is pushed, indicating a return *)
       , venv_memory =
         put_return_values v_memory (return_data r) mem_start mem_size
       , venv_memory_usage = v_memory_usage
       , venv_storage = a_storage
       , venv_pc = v_pc
       , venv_balance = (update_balance a_addr
                            (\<lambda> _. new_bal) (return_balance r))
       , venv_caller = v_caller
       , venv_value_sent = v_value
       , venv_data_sent = v_data
       , venv_storage_at_call = v_init_storage
       , venv_balance_at_call = v_init_balance
       , venv_origin = v_origin
       , venv_ext_program = v_ext_program
       , venv_block = v_block \<rparr>)"

declare build_venv_returned.simps [simp]

text {* The situation is much simpler when an ongoing call has failed because anything 
meanwhile has no effects. *}

definition build_venv_failed :: "account_state \<Rightarrow> variable_env option"
where
"build_venv_failed a =
  (case account_ongoing_calls a of
      [] \<Rightarrow> None
   | (recovered, _, _) # _ \<Rightarrow>
      (if is_call_like (* check the previous instruction *)
        (program_content (account_code a)
         (venv_pc recovered - 1)) then
       Some (recovered
         \<lparr>venv_stack := 0 (* indicating failure *) # venv_stack recovered\<rparr>)
       else None))"

declare build_venv_failed_def [simp]

subsection {* Account State Update after EVM Execution *}

text {* Of course the other direction exists for constructing an account state after
the program executes. *}

text {* The first definition is about forgetting one ongoing call. *}

declare account_state_pop_ongoing_call_def [simp]

text {* Second I define the empty account, which replaces an account that has
destroyed itself. *}
declare empty_account_def [simp]

text {* And after our contract makes a move, the account state is updated as follows.
*}
                                     
text {* The above definition should be expanded automatically only when
the last argument is known to be None or Some \_.
*}
                                     
lemma update_account_state_None [simp] :
"update_account_state prev act st bal None =
   (prev \<lparr>
     account_storage := st,
     account_balance :=
       (case act of ContractFail \<Rightarrow> account_balance prev
                 |  _ \<Rightarrow> bal (account_address prev)),
     account_ongoing_calls := account_ongoing_calls prev,
     account_killed :=
       (case act of ContractSuicide \<Rightarrow> True
                  | _ \<Rightarrow> account_killed prev) \<rparr>)"
apply(case_tac act; simp add: update_account_state_def)
done

lemma update_account_state_Some [simp] :
"update_account_state prev act st bal (Some pushed) =
   (prev \<lparr>
     account_storage := st,
     account_balance :=
       (case act of ContractFail \<Rightarrow> account_balance prev
                  |  _ \<Rightarrow> bal (account_address prev)),
     account_ongoing_calls := pushed # account_ongoing_calls prev,
     account_killed :=
       (case act of ContractSuicide \<Rightarrow> True
                  | _ \<Rightarrow> account_killed prev)\<rparr>)"
apply(case_tac act; simp add: update_account_state_def)
done


subsection {* Controlling the Isabelle Simplifier *}

text {* This subsection contains simplification rules for the Isabelle simplifier.
The main purpose is to prevent the AVL tree implementation to compute both the
left insertion and the right insertion when actually only one of these happens.
*}

declare word_rcat_def [simp]
        unat_def [simp]
        bin_rcat_def [simp]
        word_of_bytes_def [simp]
        maybe_to_list.simps [simp]


text {* There is a common pattern for checking a predicate. *}

lemma iszero_iszero [simp] :
"((if b then (1 :: 256 word) else 0) = 0) = (\<not> b) "
apply(auto)
done

end

loop:   LDA :result    ; load the :result into A
        ADD :x         ; add :x to the :result
        STA :result    ; store A into :result
        LDA :y         ; load A with the divisor
        SUB :dec       ; subtract :dec from :y (decrement)
        JZ :exit       ; if result is 0 exit the loop
        STA :y         ; store the decremented y value back to :y
        JMP :loop

exit:   LDA :result    ; put the :result into A
        OUT            ; output A
        HLT
                       ; data
result: 0
dec:    1
x:      3
y:      4

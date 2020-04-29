# li $s7, 0xFFFFD000
ori $sp, $zero, 0x00FF
lui $s7, 0xFFFF         # $s7 = 0xFFFFD000 ps2地址
ori $s7, $s7, 0xD000

lui $s6, 0x000C         # $s6 = vram_text = 0x000C0000 vga地址

lui $s5, 0x8000         # $s5 = 0x80000000 $s5最高位为1，用于取出ps2的ready信号
addi $s4, $zero, 0x00F0 # $s4 = 0x000000F0 ，F0是断码的标志，是所有key的倒数第二个断码

lui $k0, 0xFFFF         
ori $k0, $k0, 0xFC00    # $k0 = 0xFFFFFC00, button地址

init:
add $t0, $zero, $s6       # $t0 = $s6 varm_text offset
read_kbd:
# 读取阵列键盘button，这是后续添加的代码，因此函数命名还是按照之前的ps2来
lw $t1, 0($k0)            # 取出button地址上的内容，$t1 = {KRDY, 21'h0, BTN[4:0], KCODE[4:0]}
and $t2, $t1, $s5         # 取出最高位的KRDY信号,$s5=0x80000000 
beq $t2, $s5, read_btn    # 如果KRDY=1，则读取button信号并显示16进制
# 读取ps2键盘输入
lw $t1, 0($s7)            # $t1 = {1'ps2_ready, 23'h0, 8'key}
and $t2, $t1, $s5         # 取出$t1最高位的ready信号放到$t2上
beq $t2, $zero, read_kbd  # $t2=0表示没有ps2输入，此时跳回去接着读read_kbd
andi $t2, $t1, 0x00FF     # 如果ready=1，取出$t1低八位的通码
beq $t2, $s4, read        # 如果$t2=0x00F0，则说明读到了倒数第二个断码，此时跳到read来显示键盘码
j read_kbd

# 读取阵列键盘16进制数并在光标处显示
# 此时$t1为button地址线上的内容
read_btn:
add $ra, $zero, $zero     # 这里兼容我之前读取ps2的代码，设置$ra=0，这样显示完后就直接跳回读取新的信号
andi $t2, $t1, 0xFFFF     # 取出$t1的后16位放到$t2里
addi $s1, $zero, 0x0020   # $s1 = button_0
beq $t2, $s1, n0
addi $s1, $zero, 0x0041   # $s1 = button_1
beq $t2, $s1, n1
addi $s1, $zero, 0x0082   # $s1 = button_2
beq $s2, $s1, n2
addi $s1, $zero, 0x0103   # $s1 = button_3
beq $s2, $s1, n3
addi $s1, $zero, 0x0024   # $s1 = button_4
beq $s2, $s1, n4
addi $s1, $zero, 0x0045   # $s1 = button_5
beq $s2, $s1, n5
addi $s1, $zero, 0x0086   # $s1 = button_6
beq $s2, $s1, n6
addi $s1, $zero, 0x0107   # $s1 = button_7
beq $s2, $s1, n7
addi $s1, $zero, 0x0028   # $s1 = button_8
beq $s2, $s1, n8
addi $s1, $zero, 0x0049   # $s1 = button_9
beq $s2, $s1, n9
addi $s1, $zero, 0x008A   # $s1 = button_A
beq $s2, $s1, a
addi $s1, $zero, 0x010B   # $s1 = button_B
beq $s2, $s1, b
addi $s1, $zero, 0x002C   # $s1 = button_C
beq $s2, $s1, c
addi $s1, $zero, 0x004D   # $s1 = button_D
beq $s2, $s1, d
addi $s1, $zero, 0x008E   # $s1 = button_E
beq $s2, $s1, e
addi $s1, $zero, 0x010F   # $s1 = button_F
beq $s2, $s1, f
j read_kbd



read: # 读入最后一个断码，也就是key的标识码
lw $t1, 0($s7)            # $t1 = {1'ps2_ready, 23'h0, 8'key}
and $t2, $t1, $s5         # 同理，取出ready信号
beq $t2, $zero, read_kbd  # ready=0，则回去重新读
andi $t2, $t1, 0x00FF     # 否则，取出低八位的断码(标识码)

add $t1, $zero, $t0       # 先把当前光标位置$t0保存在$t1里
addi $t0, $s6, 9280       # $t0等于最后一行第一个点的地址，4*2400-4*80=9280
add $a0, $zero, $t2       # $a0=断码
addi $a1, $zero, 8        
jal display_num           # 显示8位断码
add $t0, $zero, $t1       # 还原$t0为当前光标地址

add $ra, $zero, $zero     # branch语句无法对$ra赋值来进行跳回，因此把$ra置为0来表明这是显示键盘码，执行完显示函数后直接跳回read_kbd即可

addi $s1, $zero, 0x1c     # $s1 = "a"
beq  $t2, $s1, a          # if $t2 == "a", then display "a"
addi $s1, $zero, 0x32     # $s1 = "b"
beq  $t2, $s1, b          # if $t2 == "b", then display "b"
addi $s1, $zero, 0x21     # $s1 = "c"
beq  $t2, $s1, c          # if $t2 == "c", then display "c"
addi $s1, $zero, 0x23     # $s1 = "d"
beq  $t2, $s1, d          # if $t2 == "d", then display "d"
addi $s1, $zero, 0x24     # $s1 = "e"
beq  $t2, $s1, e          # if $t2 == "e", then display "e"
addi $s1, $zero, 0x2b     # $s1 = "f"
beq  $t2, $s1, f          # if $t2 == "f", then display "f"
addi $s1, $zero, 0x34     # $s1 = "g"
beq  $t2, $s1, g          # if $t2 == "g", then display "g"
addi $s1, $zero, 0x33     # $s1 = "h"
beq  $t2, $s1, h          # if $t2 == "h", then display "h"
addi $s1, $zero, 0x43     # $s1 = "i"
beq  $t2, $s1, i          # if $t2 == "i", then display "i"
addi $s1, $zero, 0x3b     # $s1 = "j"
beq  $t2, $s1, j          # if $t2 == "j", then display "j"
addi $s1, $zero, 0x42     # $s1 = "k"
beq  $t2, $s1, k          # if $t2 == "k", then display "k"
addi $s1, $zero, 0x4b     # $s1 = "l"
beq  $t2, $s1, l          # if $t2 == "l", then display "l"
addi $s1, $zero, 0x3a     # $s1 = "m"
beq  $t2, $s1, m          # if $t2 == "m", then display "m"
addi $s1, $zero, 0x31     # $s1 = "n"
beq  $t2, $s1, n          # if $t2 == "n", then display "n"
addi $s1, $zero, 0x44     # $s1 = "o"
beq  $t2, $s1, o          # if $t2 == "o", then display "o"
addi $s1, $zero, 0x4d     # $s1 = "p"
beq  $t2, $s1, p          # if $t2 == "p", then display "p"
addi $s1, $zero, 0x15     # $s1 = "q"
beq  $t2, $s1, q          # if $t2 == "q", then display "q"
addi $s1, $zero, 0x2d     # $s1 = "r"
beq  $t2, $s1, r          # if $t2 == "r", then display "r"
addi $s1, $zero, 0x1b     # $s1 = "s"
beq  $t2, $s1, s          # if $t2 == "s", then display "s"
addi $s1, $zero, 0x2c     # $s1 = "t"
beq  $t2, $s1, t          # if $t2 == "t", then display "t"
addi $s1, $zero, 0x3c     # $s1 = "u"
beq  $t2, $s1, u          # if $t2 == "u", then display "u"
addi $s1, $zero, 0x2a     # $s1 = "v"
beq  $t2, $s1, v          # if $t2 == "v", then display "v"
addi $s1, $zero, 0x1d     # $s1 = "w"
beq  $t2, $s1, w          # if $t2 == "w", then display "w"
addi $s1, $zero, 0x22     # $s1 = "x"
beq  $t2, $s1, x          # if $t2 == "x", then display "x"
addi $s1, $zero, 0x35     # $s1 = "y"
beq  $t2, $s1, y          # if $t2 == "y", then display "y"
addi $s1, $zero, 0x1a     # $s1 = "z"
beq  $t2, $s1, z          # if $t2 == "z", then display "z"
addi $s1, $zero, 0x45     # $s1 = "0"
beq  $t2, $s1, n0         # if $t2 == "0", then display "0"
addi $s1, $zero, 0x16     # $s1 = "1"
beq  $t2, $s1, n1         # if $t2 == "1", then display "1"
addi $s1, $zero, 0x1E     # $s1 = "2"
beq  $t2, $s1, n2         # if $t2 == "2", then display "2"
addi $s1, $zero, 0x26     # $s1 = "3"
beq  $t2, $s1, n3         # if $t2 == "3", then display "3"
addi $s1, $zero, 0x25     # $s1 = "4"
beq  $t2, $s1, n4         # if $t2 == "4", then display "4"
addi $s1, $zero, 0x2E     # $s1 = "5"
beq  $t2, $s1, n5         # if $t2 == "5", then display "5"
addi $s1, $zero, 0x36     # $s1 = "6"
beq  $t2, $s1, n6         # if $t2 == "6", then display "6"
addi $s1, $zero, 0x3d     # $s1 = "7"
beq  $t2, $s1, n7         # if $t2 == "7", then display "7"
addi $s1, $zero, 0x3E     # $s1 = "8"
beq  $t2, $s1, n8         # if $t2 == "8", then display "8"
addi $s1, $zero, 0x46     # $s1 = "9"
beq  $t2, $s1, n9         # if $t2 == "9", then display "9"

addi $s1, $zero, 0x29     # $s1 = "space"
beq  $t2, $s1, space      # if $t2 == "space", then display "space"
addi $s1, $zero, 0x5a     # $s1 = "enter"
beq  $t2, $s1, enter      # if $t2 == "enter", then display "enter"
addi $s1, $zero, 0x66     # $s1 = "backspace"
beq  $t2, $s1, backspace  # if $t2 == "backspace", then display "backspace"

addi $s1, $zero, 0x75       # $s1 = "up"
beq  $t2, $s1, up           # if $t2 == "up", then display "up"
addi $s1, $zero, 0x72       # $s1 = "down"
beq  $t2, $s1, down         # if $t2 == "down", then display "down"
addi $s1, $zero, 0x6B       # $s1 = "left"
beq  $t2, $s1, left         # if $t2 == "left", then display "left"
addi $s1, $zero, 0x74       # $s1 = "right"
beq  $t2, $s1, right        # if $t2 == "right", then display "right"

addi $s1, $zero, 0x0d       # $s1 = "tab"
beq  $t2, $s1, toGraph      # if $t2 == "tab", then change mode into graph
addi $s1, $zero, 0x76       # $s1 = "esc"
beq  $t2, $s1, clear        # if $t2 == "esc", then clear

addi $s1, $zero, 0x4E       # $s1 = "-"
beq $t2, $s1, downScreen    # if $t2 == "-", then 屏幕下移一行
addi $s1, $zero, 0x55       # $s1 = "+"
beq $t2, $s1, upScreen      # if $t2 == "+", then 屏幕上移一行

j read_kbd

# 字符显示函数的调用有两种途径：1、显示键盘码，此时$ra=0，执行完后直接跳到read_kbd重新读取ps2；2、某些函数相要直接显示字符，此时显示完后返回$ra的地址
# 对字符A~Z、0~9，以下函数会同时显示该字符和它的ASCII码
a:
addi $sp, $sp, -12
sw $t1, 8($sp)
sw $s1, 4($sp)
sw $ra, 0($sp)
ori $s0, $zero, 0x0F41    # $s0 = ascii_of "a" with color
jal display               # 显示字符"a"
# 还是直接写ASCII码，不调用display_num了，避免套娃   
addi $t1, $s6, 8960         # 倒数第二行第一个点的地址
addi $s1, $zero, 0x0634     # $s1 = '4' with yellow color
sw $s1, 0($t1)              # 显示黄色的'4'
addi $t1, $t1, 4            # 倒数第二行第二个点的地址
addi $s1, $zero, 0x0631     # $s1 = '1' with yellow color
sw $s1, 0($t1)              # 显示黄色的'1'
lw $ra, 0($sp)
lw $s1, 4($sp)
lw $t1, 8($sp)
addi $sp, $sp, 12
beq $ra, $zero, read_kbd  # 如果$ra=0，说明显示的是键盘码，此时返回键盘码读取函数read_kbd
jr $ra

b:
addi $sp, $sp, -12
sw $t1, 8($sp)
sw $s1, 4($sp)
sw $ra, 0($sp)
ori $s0, $zero, 0x0F42    # $s0 = ascii_of "b" with color
jal display
addi $t1, $s6, 8960         # 倒数第二行第一个点的地址
addi $s1, $zero, 0x0634     # $s1 = '4' with yellow color
sw $s1, 0($t1)              # 显示黄色的'4'
addi $t1, $t1, 4            # 倒数第二行第二个点的地址
addi $s1, $zero, 0x0632     # $s1 = '2' with yellow color
sw $s1, 0($t1)              # 显示黄色的'2'
lw $ra, 0($sp)
lw $s1, 4($sp)
lw $t1, 8($sp)
addi $sp, $sp, 12
beq $ra, $zero, read_kbd
jr $ra

c:
addi $sp, $sp, -12
sw $t1, 8($sp)
sw $s1, 4($sp)
sw $ra, 0($sp)
ori $s0, $zero, 0x0F43    # $s0 = ascii_of "c" with color
jal display
addi $t1, $s6, 8960         # 倒数第二行第一个点的地址
addi $s1, $zero, 0x0634     # $s1 = '4' with yellow color
sw $s1, 0($t1)              # 显示黄色的'4'
addi $t1, $t1, 4            # 倒数第二行第二个点的地址
addi $s1, $zero, 0x0633     # $s1 = '3' with yellow color
sw $s1, 0($t1)              # 显示黄色的'3'
lw $ra, 0($sp)
lw $s1, 4($sp)
lw $t1, 8($sp)
addi $sp, $sp, 12
beq $ra, $zero, read_kbd
jr $ra

d:
addi $sp, $sp, -12
sw $t1, 8($sp)
sw $s1, 4($sp)
sw $ra, 0($sp)
ori $s0, $zero, 0x0F44    # $s0 = ascii_of "d" with color
jal display
addi $t1, $s6, 8960         # 倒数第二行第一个点的地址
addi $s1, $zero, 0x0634     # $s1 = '4' with yellow color
sw $s1, 0($t1)              # 显示黄色的'4'
addi $t1, $t1, 4            # 倒数第二行第二个点的地址
addi $s1, $zero, 0x0634     # $s1 = '4' with yellow color
sw $s1, 0($t1)              # 显示黄色的'4'
lw $ra, 0($sp)
lw $s1, 4($sp)
lw $t1, 8($sp)
addi $sp, $sp, 12
beq $ra, $zero, read_kbd
jr $ra

e:
addi $sp, $sp, -12
sw $t1, 8($sp)
sw $s1, 4($sp)
sw $ra, 0($sp)
ori $s0, $zero, 0x0F45    # $s0 = ascii_of "5" with color
jal display
addi $t1, $s6, 8960         # 倒数第二行第一个点的地址
addi $s1, $zero, 0x0634     # $s1 = '4' with yellow color
sw $s1, 0($t1)              # 显示黄色的'4'
addi $t1, $t1, 4            # 倒数第二行第二个点的地址
addi $s1, $zero, 0x0635     # $s1 = '5' with yellow color
sw $s1, 0($t1)              # 显示黄色的'5'
lw $ra, 0($sp)
lw $s1, 4($sp)
lw $t1, 8($sp)
addi $sp, $sp, 12
beq $ra, $zero, read_kbd
jr $ra

f:
addi $sp, $sp, -12
sw $t1, 8($sp)
sw $s1, 4($sp)
sw $ra, 0($sp)
ori $s0, $zero, 0x0F46    # $s0 = ascii_of "f" with color
jal display
addi $t1, $s6, 8960         # 倒数第二行第一个点的地址
addi $s1, $zero, 0x0634     # $s1 = '4' with yellow color
sw $s1, 0($t1)              # 显示黄色的'4'
addi $t1, $t1, 4            # 倒数第二行第二个点的地址
addi $s1, $zero, 0x0636     # $s1 = '6' with yellow color
sw $s1, 0($t1)              # 显示黄色的'6'
lw $ra, 0($sp)
lw $s1, 4($sp)
lw $t1, 8($sp)
addi $sp, $sp, 12
beq $ra, $zero, read_kbd
jr $ra

g:
addi $sp, $sp, -12
sw $t1, 8($sp)
sw $s1, 4($sp)
sw $ra, 0($sp)
ori $s0, $zero, 0x0F47    # $s0 = ascii_of "g" with color
jal display
addi $t1, $s6, 8960         # 倒数第二行第一个点的地址
addi $s1, $zero, 0x0634     # $s1 = '4' with yellow color
sw $s1, 0($t1)              # 显示黄色的'4'
addi $t1, $t1, 4            # 倒数第二行第二个点的地址
addi $s1, $zero, 0x0637     # $s1 = '7' with yellow color
sw $s1, 0($t1)              # 显示黄色的'7'
lw $ra, 0($sp)
lw $s1, 4($sp)
lw $t1, 8($sp)
addi $sp, $sp, 12
beq $ra, $zero, read_kbd
jr $ra

h:
addi $sp, $sp, -12
sw $t1, 8($sp)
sw $s1, 4($sp)
sw $ra, 0($sp)
ori $s0, $zero, 0x0F48    # $s0 = ascii_of "h" with color
jal display
addi $t1, $s6, 8960         # 倒数第二行第一个点的地址
addi $s1, $zero, 0x0634     # $s1 = '4' with yellow color
sw $s1, 0($t1)              # 显示黄色的'4'
addi $t1, $t1, 4            # 倒数第二行第二个点的地址
addi $s1, $zero, 0x0638     # $s1 = '8' with yellow color
sw $s1, 0($t1)              # 显示黄色的'8'
lw $ra, 0($sp)
lw $s1, 4($sp)
lw $t1, 8($sp)
addi $sp, $sp, 12
beq $ra, $zero, read_kbd
jr $ra

i:
addi $sp, $sp, -12
sw $t1, 8($sp)
sw $s1, 4($sp)
sw $ra, 0($sp)
ori $s0, $zero, 0x0F49    # $s0 = ascii_of "i" with color
jal display
addi $t1, $s6, 8960         # 倒数第二行第一个点的地址
addi $s1, $zero, 0x0634     # $s1 = '4' with yellow color
sw $s1, 0($t1)              # 显示黄色的'4'
addi $t1, $t1, 4            # 倒数第二行第二个点的地址
addi $s1, $zero, 0x0639     # $s1 = '9' with yellow color
sw $s1, 0($t1)              # 显示黄色的'9'
lw $ra, 0($sp)
lw $s1, 4($sp)
lw $t1, 8($sp)
addi $sp, $sp, 12
beq $ra, $zero, read_kbd
jr $ra

j:
addi $sp, $sp, -12
sw $t1, 8($sp)
sw $s1, 4($sp)
sw $ra, 0($sp)
ori $s0, $zero, 0x0F4A    # $s0 = ascii_of "j" with color
jal display
addi $t1, $s6, 8960         # 倒数第二行第一个点的地址
addi $s1, $zero, 0x0634     # $s1 = '4' with yellow color
sw $s1, 0($t1)              # 显示黄色的'4'
addi $t1, $t1, 4            # 倒数第二行第二个点的地址
addi $s1, $zero, 0x0641     # $s1 = 'A' with yellow color
sw $s1, 0($t1)              # 显示黄色的'A'
lw $ra, 0($sp)
lw $s1, 4($sp)
lw $t1, 8($sp)
addi $sp, $sp, 12
beq $ra, $zero, read_kbd
jr $ra

k:
addi $sp, $sp, -12
sw $t1, 8($sp)
sw $s1, 4($sp)
sw $ra, 0($sp)
ori $s0, $zero, 0x0F4B    # $s0 = ascii_of "k" with color
jal display
addi $t1, $s6, 8960         # 倒数第二行第一个点的地址
addi $s1, $zero, 0x0634     # $s1 = '4' with yellow color
sw $s1, 0($t1)              # 显示黄色的'4'
addi $t1, $t1, 4            # 倒数第二行第二个点的地址
addi $s1, $zero, 0x0642     # $s1 = 'B' with yellow color
sw $s1, 0($t1)              # 显示黄色的'B'
lw $ra, 0($sp)
lw $s1, 4($sp)
lw $t1, 8($sp)
addi $sp, $sp, 12
beq $ra, $zero, read_kbd
jr $ra

l:
addi $sp, $sp, -12
sw $t1, 8($sp)
sw $s1, 4($sp)
sw $ra, 0($sp)
ori $s0, $zero, 0x0F4C    # $s0 = ascii_of "l" with color
jal display
addi $t1, $s6, 8960         # 倒数第二行第一个点的地址
addi $s1, $zero, 0x0634     # $s1 = '4' with yellow color
sw $s1, 0($t1)              # 显示黄色的'4'
addi $t1, $t1, 4            # 倒数第二行第二个点的地址
addi $s1, $zero, 0x0643     # $s1 = 'C' with yellow color
sw $s1, 0($t1)              # 显示黄色的'C'
lw $ra, 0($sp)
lw $s1, 4($sp)
lw $t1, 8($sp)
addi $sp, $sp, 12
beq $ra, $zero, read_kbd
jr $ra

m:
addi $sp, $sp, -12
sw $t1, 8($sp)
sw $s1, 4($sp)
sw $ra, 0($sp)
ori $s0, $zero, 0x0F4D    # $s0 = ascii_of "m" with color
jal display
addi $t1, $s6, 8960         # 倒数第二行第一个点的地址
addi $s1, $zero, 0x0634     # $s1 = '4' with yellow color
sw $s1, 0($t1)              # 显示黄色的'4'
addi $t1, $t1, 4            # 倒数第二行第二个点的地址
addi $s1, $zero, 0x0644     # $s1 = 'D' with yellow color
sw $s1, 0($t1)              # 显示黄色的'D'
lw $ra, 0($sp)
lw $s1, 4($sp)
lw $t1, 8($sp)
addi $sp, $sp, 12
beq $ra, $zero, read_kbd
jr $ra

n:
addi $sp, $sp, -12
sw $t1, 8($sp)
sw $s1, 4($sp)
sw $ra, 0($sp)
ori $s0, $zero, 0x0F4E    # $s0 = ascii_of "n" with color
jal display
addi $t1, $s6, 8960         # 倒数第二行第一个点的地址
addi $s1, $zero, 0x0634     # $s1 = '4' with yellow color
sw $s1, 0($t1)              # 显示黄色的'4'
addi $t1, $t1, 4            # 倒数第二行第二个点的地址
addi $s1, $zero, 0x0645     # $s1 = 'E' with yellow color
sw $s1, 0($t1)              # 显示黄色的'E'
lw $ra, 0($sp)
lw $s1, 4($sp)
lw $t1, 8($sp)
addi $sp, $sp, 12
beq $ra, $zero, read_kbd
jr $ra

o:
addi $sp, $sp, -12
sw $t1, 8($sp)
sw $s1, 4($sp)
sw $ra, 0($sp)
ori $s0, $zero, 0x0F4F    # $s0 = ascii_of "o" with color
jal display
addi $t1, $s6, 8960         # 倒数第二行第一个点的地址
addi $s1, $zero, 0x0634     # $s1 = '4' with yellow color
sw $s1, 0($t1)              # 显示黄色的'4'
addi $t1, $t1, 4            # 倒数第二行第二个点的地址
addi $s1, $zero, 0x0646     # $s1 = 'F' with yellow color
sw $s1, 0($t1)              # 显示黄色的'F'
lw $ra, 0($sp)
lw $s1, 4($sp)
lw $t1, 8($sp)
addi $sp, $sp, 12
beq $ra, $zero, read_kbd
jr $ra

p:
addi $sp, $sp, -12
sw $t1, 8($sp)
sw $s1, 4($sp)
sw $ra, 0($sp)
ori $s0, $zero, 0x0F50    # $s0 = ascii_of "p" with color
jal display
addi $t1, $s6, 8960         # 倒数第二行第一个点的地址
addi $s1, $zero, 0x0635     # $s1 = '5' with yellow color
sw $s1, 0($t1)              # 显示黄色的'5'
addi $t1, $t1, 4            # 倒数第二行第二个点的地址
addi $s1, $zero, 0x0630     # $s1 = '0' with yellow color
sw $s1, 0($t1)              # 显示黄色的'0'
lw $ra, 0($sp)
lw $s1, 4($sp)
lw $t1, 8($sp)
addi $sp, $sp, 12
beq $ra, $zero, read_kbd
jr $ra

q:
addi $sp, $sp, -12
sw $t1, 8($sp)
sw $s1, 4($sp)
sw $ra, 0($sp)
ori $s0, $zero, 0x0F51    # $s0 = ascii_of "q" with color
jal display
addi $t1, $s6, 8960         # 倒数第二行第一个点的地址
addi $s1, $zero, 0x0635     # $s1 = '5' with yellow color
sw $s1, 0($t1)              # 显示黄色的'5'
addi $t1, $t1, 4            # 倒数第二行第二个点的地址
addi $s1, $zero, 0x0631     # $s1 = '1' with yellow color
sw $s1, 0($t1)              # 显示黄色的'1'
lw $ra, 0($sp)
lw $s1, 4($sp)
lw $t1, 8($sp)
addi $sp, $sp, 12
beq $ra, $zero, read_kbd
jr $ra

r:
addi $sp, $sp, -12
sw $t1, 8($sp)
sw $s1, 4($sp)
sw $ra, 0($sp)
ori $s0, $zero, 0x0F52    # $s0 = ascii_of "r" with color
jal display
addi $t1, $s6, 8960         # 倒数第二行第一个点的地址
addi $s1, $zero, 0x0635     # $s1 = '5' with yellow color
sw $s1, 0($t1)              # 显示黄色的'5'
addi $t1, $t1, 4            # 倒数第二行第二个点的地址
addi $s1, $zero, 0x0632     # $s1 = '2' with yellow color
sw $s1, 0($t1)              # 显示黄色的'02
lw $ra, 0($sp)
lw $s1, 4($sp)
lw $t1, 8($sp)
addi $sp, $sp, 12
beq $ra, $zero, read_kbd
jr $ra

s:
addi $sp, $sp, -12
sw $t1, 8($sp)
sw $s1, 4($sp)
sw $ra, 0($sp)
ori $s0, $zero, 0x0F53    # $s0 = ascii_of "s" with color
jal display
addi $t1, $s6, 8960         # 倒数第二行第一个点的地址
addi $s1, $zero, 0x0635     # $s1 = '5' with yellow color
sw $s1, 0($t1)              # 显示黄色的'5'
addi $t1, $t1, 4            # 倒数第二行第二个点的地址
addi $s1, $zero, 0x0633     # $s1 = '3' with yellow color
sw $s1, 0($t1)              # 显示黄色的'3'
lw $ra, 0($sp)
lw $s1, 4($sp)
lw $t1, 8($sp)
addi $sp, $sp, 12
beq $ra, $zero, read_kbd
jr $ra

t:
addi $sp, $sp, -12
sw $t1, 8($sp)
sw $s1, 4($sp)
sw $ra, 0($sp)
ori $s0, $zero, 0x0F54    # $s0 = ascii_of "t" with color
jal display
addi $t1, $s6, 8960         # 倒数第二行第一个点的地址
addi $s1, $zero, 0x0635     # $s1 = '5' with yellow color
sw $s1, 0($t1)              # 显示黄色的'5'
addi $t1, $t1, 4            # 倒数第二行第二个点的地址
addi $s1, $zero, 0x0634     # $s1 = '4' with yellow color
sw $s1, 0($t1)              # 显示黄色的'04
lw $ra, 0($sp)
lw $s1, 4($sp)
lw $t1, 8($sp)
addi $sp, $sp, 12
beq $ra, $zero, read_kbd
jr $ra

u:
addi $sp, $sp, -12
sw $t1, 8($sp)
sw $s1, 4($sp)
sw $ra, 0($sp)
ori $s0, $zero, 0x0F55    # $s0 = ascii_of "u" with color
jal display
addi $t1, $s6, 8960         # 倒数第二行第一个点的地址
addi $s1, $zero, 0x0635     # $s1 = '5' with yellow color
sw $s1, 0($t1)              # 显示黄色的'5'
addi $t1, $t1, 4            # 倒数第二行第二个点的地址
addi $s1, $zero, 0x0635     # $s1 = '5' with yellow color
sw $s1, 0($t1)              # 显示黄色的'5'
lw $ra, 0($sp)
lw $s1, 4($sp)
lw $t1, 8($sp)
addi $sp, $sp, 12
beq $ra, $zero, read_kbd
jr $ra

v:
addi $sp, $sp, -12
sw $t1, 8($sp)
sw $s1, 4($sp)
sw $ra, 0($sp)
ori $s0, $zero, 0x0F56    # $s0 = ascii_of "v" with color
jal display
addi $t1, $s6, 8960         # 倒数第二行第一个点的地址
addi $s1, $zero, 0x0635     # $s1 = '5' with yellow color
sw $s1, 0($t1)              # 显示黄色的'5'
addi $t1, $t1, 4            # 倒数第二行第二个点的地址
addi $s1, $zero, 0x0636     # $s1 = '6' with yellow color
sw $s1, 0($t1)              # 显示黄色的'6'
lw $ra, 0($sp)
lw $s1, 4($sp)
lw $t1, 8($sp)
addi $sp, $sp, 12
beq $ra, $zero, read_kbd
jr $ra

w:
addi $sp, $sp, -12
sw $t1, 8($sp)
sw $s1, 4($sp)
sw $ra, 0($sp)
ori $s0, $zero, 0x0F57    # $s0 = ascii_of "w" with color
jal display
addi $t1, $s6, 8960         # 倒数第二行第一个点的地址
addi $s1, $zero, 0x0635     # $s1 = '5' with yellow color
sw $s1, 0($t1)              # 显示黄色的'5'
addi $t1, $t1, 4            # 倒数第二行第二个点的地址
addi $s1, $zero, 0x0637     # $s1 = '7' with yellow color
sw $s1, 0($t1)              # 显示黄色的'7'
lw $ra, 0($sp)
lw $s1, 4($sp)
lw $t1, 8($sp)
addi $sp, $sp, 12
beq $ra, $zero, read_kbd
jr $ra

x:
addi $sp, $sp, -12
sw $t1, 8($sp)
sw $s1, 4($sp)
sw $ra, 0($sp)
ori $s0, $zero, 0x0F58    # $s0 = ascii_of "x" with color
jal display
addi $t1, $s6, 8960         # 倒数第二行第一个点的地址
addi $s1, $zero, 0x0635     # $s1 = '5' with yellow color
sw $s1, 0($t1)              # 显示黄色的'5'
addi $t1, $t1, 4            # 倒数第二行第二个点的地址
addi $s1, $zero, 0x0638     # $s1 = '8' with yellow color
sw $s1, 0($t1)              # 显示黄色的'8'
lw $ra, 0($sp)
lw $s1, 4($sp)
lw $t1, 8($sp)
addi $sp, $sp, 12
beq $ra, $zero, read_kbd
jr $ra

y:
addi $sp, $sp, -12
sw $t1, 8($sp)
sw $s1, 4($sp)
sw $ra, 0($sp)
ori $s0, $zero, 0x0F59    # $s0 = ascii_of "y" with color
jal display
addi $t1, $s6, 8960         # 倒数第二行第一个点的地址
addi $s1, $zero, 0x0635     # $s1 = '5' with yellow color
sw $s1, 0($t1)              # 显示黄色的'5'
addi $t1, $t1, 4            # 倒数第二行第二个点的地址
addi $s1, $zero, 0x0639     # $s1 = '9' with yellow color
sw $s1, 0($t1)              # 显示黄色的'9'
lw $ra, 0($sp)
lw $s1, 4($sp)
lw $t1, 8($sp)
addi $sp, $sp, 12
beq $ra, $zero, read_kbd
jr $ra

z:
addi $sp, $sp, -12
sw $t1, 8($sp)
sw $s1, 4($sp)
sw $ra, 0($sp)
ori $s0, $zero, 0x0F5A    # $s0 = ascii_of "z" with color
jal display
addi $t1, $s6, 8960         # 倒数第二行第一个点的地址
addi $s1, $zero, 0x0635     # $s1 = '5' with yellow color
sw $s1, 0($t1)              # 显示黄色的'5'
addi $t1, $t1, 4            # 倒数第二行第二个点的地址
addi $s1, $zero, 0x0641     # $s1 = 'A' with yellow color
sw $s1, 0($t1)              # 显示黄色的'A'
lw $ra, 0($sp)
lw $s1, 4($sp)
lw $t1, 8($sp)
addi $sp, $sp, 12
beq $ra, $zero, read_kbd
jr $ra

n0:
addi $sp, $sp, -12
sw $t1, 8($sp)
sw $s1, 4($sp)
sw $ra, 0($sp)
ori $s0, $zero, 0x0F30    # $s0 = ascii_of "0" with color
jal display
addi $t1, $s6, 8960         # 倒数第二行第一个点的地址
addi $s1, $zero, 0x0633     # $s1 = '3' with yellow color
sw $s1, 0($t1)              # 显示黄色的'3'
addi $t1, $t1, 4            # 倒数第二行第二个点的地址
addi $s1, $zero, 0x0630     # $s1 = '0' with yellow color
sw $s1, 0($t1)              # 显示黄色的'0'
lw $ra, 0($sp)
lw $s1, 4($sp)
lw $t1, 8($sp)
addi $sp, $sp, 12
beq $ra, $zero, read_kbd
jr $ra

n1:
addi $sp, $sp, -12
sw $t1, 8($sp)
sw $s1, 4($sp)
sw $ra, 0($sp)
ori $s0, $zero, 0x0F31    # $s0 = ascii_of "1" with color
jal display
addi $t1, $s6, 8960         # 倒数第二行第一个点的地址
addi $s1, $zero, 0x0633     # $s1 = '3' with yellow color
sw $s1, 0($t1)              # 显示黄色的'3'
addi $t1, $t1, 4            # 倒数第二行第二个点的地址
addi $s1, $zero, 0x0631     # $s1 = '1' with yellow color
sw $s1, 0($t1)              # 显示黄色的'1'
lw $ra, 0($sp)
lw $s1, 4($sp)
lw $t1, 8($sp)
addi $sp, $sp, 12
beq $ra, $zero, read_kbd
jr $ra

n2:
addi $sp, $sp, -12
sw $t1, 8($sp)
sw $s1, 4($sp)
sw $ra, 0($sp)
ori $s0, $zero, 0x0F32    # $s0 = ascii_of "2" with color
jal display
addi $t1, $s6, 8960         # 倒数第二行第一个点的地址
addi $s1, $zero, 0x0633     # $s1 = '3' with yellow color
sw $s1, 0($t1)              # 显示黄色的'3'
addi $t1, $t1, 4            # 倒数第二行第二个点的地址
addi $s1, $zero, 0x0632     # $s1 = '2' with yellow color
sw $s1, 0($t1)              # 显示黄色的'2'
lw $ra, 0($sp)
lw $s1, 4($sp)
lw $t1, 8($sp)
addi $sp, $sp, 12
beq $ra, $zero, read_kbd
jr $ra

n3:
addi $sp, $sp, -12
sw $t1, 8($sp)
sw $s1, 4($sp)
sw $ra, 0($sp)
ori $s0, $zero, 0x0F33    # $s0 = ascii_of "3" with color
jal display
addi $t1, $s6, 8960         # 倒数第二行第一个点的地址
addi $s1, $zero, 0x0633     # $s1 = '3' with yellow color
sw $s1, 0($t1)              # 显示黄色的'3'
addi $t1, $t1, 4            # 倒数第二行第二个点的地址
addi $s1, $zero, 0x0633     # $s1 = '3' with yellow color
sw $s1, 0($t1)              # 显示黄色的'3'
lw $ra, 0($sp)
lw $s1, 4($sp)
lw $t1, 8($sp)
addi $sp, $sp, 12
beq $ra, $zero, read_kbd
jr $ra

n4:
addi $sp, $sp, -12
sw $t1, 8($sp)
sw $s1, 4($sp)
sw $ra, 0($sp)
ori $s0, $zero, 0x0F34    # $s0 = ascii_of "4" with color
jal display
addi $t1, $s6, 8960         # 倒数第二行第一个点的地址
addi $s1, $zero, 0x0633     # $s1 = '3' with yellow color
sw $s1, 0($t1)              # 显示黄色的'3'
addi $t1, $t1, 4            # 倒数第二行第二个点的地址
addi $s1, $zero, 0x0634     # $s1 = '4' with yellow color
sw $s1, 0($t1)              # 显示黄色的'4'
lw $ra, 0($sp)
lw $s1, 4($sp)
lw $t1, 8($sp)
addi $sp, $sp, 12
beq $ra, $zero, read_kbd
jr $ra

n5:
addi $sp, $sp, -12
sw $t1, 8($sp)
sw $s1, 4($sp)
sw $ra, 0($sp)
ori $s0, $zero, 0x0F35    # $s0 = ascii_of "5" with color
jal display
addi $t1, $s6, 8960         # 倒数第二行第一个点的地址
addi $s1, $zero, 0x0633     # $s1 = '3' with yellow color
sw $s1, 0($t1)              # 显示黄色的'3'
addi $t1, $t1, 4            # 倒数第二行第二个点的地址
addi $s1, $zero, 0x0635     # $s1 = '5' with yellow color
sw $s1, 0($t1)              # 显示黄色的'5'
lw $ra, 0($sp)
lw $s1, 4($sp)
lw $t1, 8($sp)
addi $sp, $sp, 12
beq $ra, $zero, read_kbd
jr $ra

n6:
addi $sp, $sp, -12
sw $t1, 8($sp)
sw $s1, 4($sp)
sw $ra, 0($sp)
ori $s0, $zero, 0x0F36    # $s0 = ascii_of "6" with color
jal display
addi $t1, $s6, 8960         # 倒数第二行第一个点的地址
addi $s1, $zero, 0x0633     # $s1 = '3' with yellow color
sw $s1, 0($t1)              # 显示黄色的'3'
addi $t1, $t1, 4            # 倒数第二行第二个点的地址
addi $s1, $zero, 0x0636     # $s1 = '6' with yellow color
sw $s1, 0($t1)              # 显示黄色的'6'
lw $ra, 0($sp)
lw $s1, 4($sp)
lw $t1, 8($sp)
addi $sp, $sp, 12
beq $ra, $zero, read_kbd
jr $ra

n7:
addi $sp, $sp, -12
sw $t1, 8($sp)
sw $s1, 4($sp)
sw $ra, 0($sp)
ori $s0, $zero, 0x0F37    # $s0 = ascii_of "7" with color
jal display
addi $t1, $s6, 8960         # 倒数第二行第一个点的地址
addi $s1, $zero, 0x0633     # $s1 = '3' with yellow color
sw $s1, 0($t1)              # 显示黄色的'3'
addi $t1, $t1, 4            # 倒数第二行第二个点的地址
addi $s1, $zero, 0x0637     # $s1 = '7' with yellow color
sw $s1, 0($t1)              # 显示黄色的'7'
lw $ra, 0($sp)
lw $s1, 4($sp)
lw $t1, 8($sp)
addi $sp, $sp, 12
beq $ra, $zero, read_kbd
jr $ra

n8:
addi $sp, $sp, -12
sw $t1, 8($sp)
sw $s1, 4($sp)
sw $ra, 0($sp)
ori $s0, $zero, 0x0F38    # $s0 = ascii_of "8" with color
jal display
addi $t1, $s6, 8960         # 倒数第二行第一个点的地址
addi $s1, $zero, 0x0633     # $s1 = '3' with yellow color
sw $s1, 0($t1)              # 显示黄色的'3'
addi $t1, $t1, 4            # 倒数第二行第二个点的地址
addi $s1, $zero, 0x0638     # $s1 = '8' with yellow color
sw $s1, 0($t1)              # 显示黄色的'8'
lw $ra, 0($sp)
lw $s1, 4($sp)
lw $t1, 8($sp)
addi $sp, $sp, 12
beq $ra, $zero, read_kbd
jr $ra

n9:
addi $sp, $sp, -12
sw $t1, 8($sp)
sw $s1, 4($sp)
sw $ra, 0($sp)
ori $s0, $zero, 0x0F39    # $s0 = ascii_of "9" with color
jal display
addi $t1, $s6, 8960         # 倒数第二行第一个点的地址
addi $s1, $zero, 0x0633     # $s1 = '3' with yellow color
sw $s1, 0($t1)              # 显示黄色的'3'
addi $t1, $t1, 4            # 倒数第二行第二个点的地址
addi $s1, $zero, 0x0639     # $s1 = '9' with yellow color
sw $s1, 0($t1)              # 显示黄色的'9'
lw $ra, 0($sp)
lw $s1, 4($sp)
lw $t1, 8($sp)
addi $sp, $sp, 12
beq $ra, $zero, read_kbd
jr $ra

# 光标cur的上下左右移动，$t8是一个全局变量，用来保存该位置原先的内容
up:
sw $t8, 0($t0)            # 把$t8中原先的内容还原到当前位置，然后再移动光标cur
addi $t0, $t0, -320       # 表示vga地址的$t0上移一行，80列*4byte
slt $t1, $t0, $s6         # 判断上移一行后是否超出屏幕
beq $t1, $zero, up_modify # 如果没有超出，则直接修改上一行的内容
addi $t0, $t0, 9600       # 如果超出，就从屏幕最下面出来，9600表示2400*4，即整个屏幕的范围
up_modify:
lw $t8, 0($t0)            # 修改前先把该位置的内容存到$t8里
addi $s0, $zero, 0x065F   # $s0=光标cur
sw $s0, 0($t0)            # 使光标在当前vga地址$t0处显示
j read_kbd

down:
sw $t8, 0($t0)            
addi $t0, $t0, 320        # 表示vga地址的$t0下移一行
addi $t1, $s6, 9600       # $t1=vga初始地址$s6+整个屏幕的offset 9600，即屏幕最后一个点的地址
slt $t1, $t0, $t1         # 判断当前vga地址$t0是否小于屏幕最后一个点的地址
bne $t1, $zero, down_modify 
addi $t0, $t0, -9600      # 如果超出屏幕范围，就从屏幕最上面出来
down_modify:              
lw $t8, 0($t0)            # 修改前先把该位置的内容存到$t8里
addi $s0, $zero, 0x065F   # $s0=光标cur
sw $s0, 0($t0)            # 使光标在当前vga地址$t0处显示
j read_kbd

left:
sw $t8, 0($t0)
addi $t0, $t0, -4
slt $t1, $t0, $s6
beq $t1, $zero, left_modify
addi $t0, $s6, 9600       # $t0=$s6+9600，屏幕最后一个点的地址
left_modify:              
lw $t8, 0($t0)            # 修改前先把该位置的内容存到$t8里
addi $s0, $zero, 0x065F   # $s0=光标cur
sw $s0, 0($t0)            # 使光标在当前vga地址$t0处显示
j read_kbd

right:
sw $t8, 0($t0)
addi $t0, $t0, 4
addi $t1, $s6, 9604
slt $t1, $t0, $t1
bne $t1, $zero, right_modify
add $t0, $s6, $zero       # $t0=$s6，表示屏幕第一个点的地址
right_modify:              
lw $t8, 0($t0)            # 修改前先把该位置的内容存到$t8里
addi $s0, $zero, 0x065F   # $s0=光标cur
sw $s0, 0($t0)            # 使光标在当前vga地址$t0处显示
j read_kbd

space: # 显示空格
add $s0, $zero, $zero    # $s0 = ascii_of "space" 
jal display
j read_kbd

backspace: # 删除键
sw $zero, 0($t0)          # clear cur
addi $t0, $t0, -4         # offset--
addi $s0, $zero, 0x065F   # $s0 = cur
sw $s0, 0($t0)            # replace the character by cur
j read_kbd

clear: # 按下esc，清屏
addi $t0, $s6, 9600       # $t0=$s6+9600，等于屏幕最后一个点的地址
clr:
sw $zero, 0($t0)          # 当前地址内容清空
addi $t0, $t0, -4         # 移动到上一个地址，offset--
bne $t0, $s6, clr         # 如果还没有移动到屏幕第一个点的地址，则继续清空
sw $zero, 0($t0)          # 达到屏幕第一个点，把它清空
j read_kbd                # 跳回read_kbd，继续读取键盘码

# 按下减号键"-"，屏幕下移一行
downScreen:
add $t1, $zero, $t0       # 获取当前光标的地址，赋值给$t1
addi $t2, $t0, 320        # 获取当前光标下移一行的地址，赋值给$t2
down_loop:
lw $s1, 0($t1)            # 取出当前光标的内容
sw $s1, 0($t2)            # 复制到下一行
addi $t1, $t1, -4         # 同时往前挪一个位置
addi $t2, $t2, -4
bne $t1, $s6, down_loop   # 如果被复制的对象还没有到达屏幕第一个点，则继续复制
lw $s1, 0($t1)            # 还要对第一个点额外做一次复制 
sw $s1, 0($t2)            
addi $t0, $t0, 320        # 更新光标的位置$t0
j read_kbd

# 按下加号键"+"，屏幕上移一行
upScreen:
add $t2, $zero, $s6         # 屏幕第一个点的地址
addi $t1, $s6, 320          # 第二行第一个点的地址
up_loop:
lw $s1, 0($t1)              # 下一行的点复制到上一行
sw $s1, 0($t2)
addi $t1, $t1, 4            # 右移一个点
addi $t2, $t2, 4
bne $t2, $t0, up_loop       # 如果还没到最后一个点，则继续复制
sw $zero, 0($t0)            # 删除原先的光标
addi $t0, $t0, -320         # 更新光标的位置$t0
j read_kbd

toGraph:
j read_kbd

enter: # 回车键，换行
# lui $a0, 0xABCD         # 测试代码
# addi $a1, $zero, 4
# jal display_num
jal display_regs
jal display_memory
jal Bin2Hex
jal Hex2ASCII
sub  $t1, $t0, $s6        # $t1=delta_offset，即当前显示地址和屏幕第一个点的地址之差
add $t2, $zero, $zero     # $t2 = 0
loop_enter:               # $t2 = k*80 && $t2 < delta_offset, 执行完该循环，$t2=当前光标下一行第一个点的地址偏移量
addi $t2, $t2, 320        # 320 = 4*80, $t2加一行
slt $t3, $t1, $t2
beq $t3, $zero, loop_enter # 如果$t2 < delta_offset, goto loop
add $t0, $s6, $t2          # update offset $t0 = 屏幕第一个点的地址 $s6 + 下一行第一个点的地址偏移量 $t2
addi $s0, $zero, 0x065F    # update $s0 into cur, yellow
sw $s0, 0($t0)             # 下一行行首显示光标
j read_kbd                 # 返回重新读取键盘码

display:
addi $sp, $sp, -4
sw $s0, 0($sp)
sw $s0, 0($t0)            # display the character $s0
addi $t0, $t0, 4          # update offset of text_vram
addi $s0, $zero, 0x065F   # update $s0 into cur, yellow
sw $s0, 0($t0)            # display cur, but no update offset
lw $s0, 0($sp)
addi $sp, $sp, 4
jr $ra                    # return 


# input: $a0: 要输出的16进制码; $a1: 要输出的16进制码位数
# output: vga显示$a1位存储在$a0里的16进制码
display_num:              # 显示$a1位16进制码
addi $sp, $sp, -20        # 先保存$ra，这里$t1、$s1在多次调用该函数时可能会被覆盖，因此也要做保存
sw $ra, 0($sp)
sw $t1, 4($sp)
sw $t2, 8($sp)
sw $s0, 12($sp)
sw $s1, 16($sp)

lui $t1, 0xF000           # $t1高四位为1，用于取出$a0的高四位，也就是8位16进制数的第一位
and $s1, $a0, $t1         # 取出$a0的高四位，放到$s1里
addi $a1, $a1, 1          # $a1 = $a1 + 1, 也就是16进制码数量的上限("<=$a1" <=> "<$a1+1")
addi $t3, $zero, 1        # $t3用于计数，当显示完8位16进制数时退出循环
j L0                      # 第一次循环时，$a0不需要左移4位，直接跳到L0
next_num:
addi $t3, $t3, 1          # $t3++
slt $t2, $t3, $a1         # 如果$t3>=$a1，则跳出display_num函数
beq $t2, $zero, exit_num
sll $a0, $a0, 4           # $a0左移四位，取下一个十六进制数
and $s1, $a0, $t1
L0: # display 0
lui $t2, 0x0000           # $t2=0~F，分别判断显示的数字
sub $t2, $s1, $t2         # 判断是否等于0
bne $t2, $zero, L1        # 这里不直接用beq跳到n0的原因是，需要用jal进行链接并跳转回来
jal n0                    # 等于0，则显示数字0
j next_num                # 执行完jal后，说明已经找到对应数字显示了，直接跳到下一位16进制数
L1: # display 1
lui $t2, 0x1000
sub $t2, $s1, $t2       
bne $t2, $zero, L2
jal n1
j next_num
L2: # display 2
lui $t2, 0x2000
sub $t2, $s1, $t2
bne $t2, $zero, L3
jal n2
j next_num
L3: # display 3
lui $t2, 0x3000
sub $t2, $s1, $t2
bne $t2, $zero, L4
jal n3
j next_num
L4: # display 4
lui $t2, 0x4000
sub $t2, $s1, $t2
bne $t2, $zero, L5
jal n4
j next_num
L5: # display 5
lui $t2, 0x5000
sub $t2, $s1, $t2
bne $t2, $zero, L6
jal n5
j next_num
L6: # display 6
lui $t2, 0x6000
sub $t2, $s1, $t2
bne $t2, $zero, L7
jal n6
j next_num
L7: # display 7
lui $t2, 0x7000
sub $t2, $s1, $t2
bne $t2, $zero, L8
jal n7
j next_num
L8: # display 8
lui $t2, 0x8000
sub $t2, $s1, $t2
bne $t2, $zero, L9
jal n8
j next_num
L9: # display 9
lui $t2, 0x9000
sub $t2, $s1, $t2
bne $t2, $zero, La
jal n9
j next_num
La: # display A
lui $t2, 0xA000
sub $t2, $s1, $t2
bne $t2, $zero, Lb
jal a
j next_num
Lb: # display B
lui $t2, 0xB000
sub $t2, $s1, $t2
bne $t2, $zero, Lc
jal b
j next_num
Lc: # display C
lui $t2, 0xC000
sub $t2, $s1, $t2
bne $t2, $zero, Ld
jal c
j next_num
Ld: # display D
lui $t2, 0xD000
sub $t2, $s1, $t2
bne $t2, $zero, Le
jal d
j next_num
Le: # display E
lui $t2, 0xE000
sub $t2, $s1, $t2
bne $t2, $zero, Lf
jal e
j next_num
Lf: # display F
lui $t2, 0xF000
sub $t2, $s1, $t2
bne $t2, $zero, next_num
jal f
j next_num
exit_num:
lw $ra, 0($sp)
lw $t1, 4($sp)
lw $t2, 8($sp)
lw $s0, 12($sp)
lw $s1, 16($sp)
addi $sp, $sp, 20
jr $ra

# 显示目标寄存器，缺省状态为显示全部32个寄存器
# 输入格式：寄存器编号 DREG，如: 12 DREG，表示显示第12号寄存器的值
display_regs:
addi $sp, $sp, -12
sw $ra, 8($sp)
sw $a0, 4($sp)
sw $a1, 0($sp)
DREG_0:
addi $t1, $t0, -16          # $t1为$t0前四个字符中第一个字符的地址，一开始用于检测DREG的"D"
lw $s1, 0($t1)              # 取出$t1地址上的字符
ori $s2, $zero, 0x0F44      # $s2 = 'D'
bne $s1, $s2, reg_return    # 如果第一个字符不是'D'，则直接跳出检测
addi $t1, $t1, 4            # 地址$t1++，检测下一个字符
DREG_1:
lw $s1, 0($t1)              # 取出$t1地址上的字符
ori $s2, $zero, 0x0F52      # $s2 = 'R'
bne $s1, $s2, reg_return    # 如果第二个字符不是'R'，则直接跳出检测
addi $t1, $t1, 4            # 地址$t1++，检测下一个字符
DREG_2:
lw $s1, 0($t1)              # 取出$t1地址上的字符
ori $s2, $zero, 0x0F45      # $s2 = 'E'
bne $s1, $s2, reg_return    # 如果第三个字符不是'E'，则直接跳出检测
addi $t1, $t1, 4            # 地址$t1++，检测下一个字符
DREG_3:
lw $s1, 0($t1)              # 取出$t1地址上的字符
ori $s2, $zero, 0x0F47      # $s3 = 'G'
bne $s1, $s2, reg_return    # 如果第四个字符不是'G'，则直接跳出检测
addi $t1, $t1, 4            # 地址$t1++
reg_digit:
bne $t1, $t0, reg_return    # 如果前4个字符不是'DREG'，则直接返回，而不显示任何内容
add $t2, $zero, $zero       # $t2用于存放寄存器编号参数
addi $t1, $t0, -24           # 2位寄存器编号参数的低位
lw $s1, 0($t1)              # 取出低位值$s1
ori $t4, $zero, 0x0F30      # 如果低位值$s1不在0~9范围内，则$t2=0直接显示
ori $t5, $zero, 0x0F39
slt $t3, $s1, $t4
bne $t3, $zero, reg_display
slt $t3, $t5, $s1
bne $t3, $zero, reg_display
sub $t2, $s1, $t4           # 0~9: 0x0F30-0x0F39; A~F: 0x0F41-0x0F46,所以 $t2 = $s1 - 0x0F30
addi $t1, $t1, -4           # 取出高位值
lw $s1, 0($t1)
ori $t5, $zero, 0x0F33      # 如果高位不在0~3的范围内，则直接显示低位表示的寄存器
slt $t3, $s1, $t4
bne $t3, $zero, reg_display
slt $t3, $t5, $s1
bne $t3, $zero, reg_display
sub $t3, $s1, $t4           # $t3是高位数字，需要乘10
sll $t4, $t3, 3             # $t4=$t3*8
sll $t5, $t3, 1             # $t5=$t3*2
add $t3, $t4, $t5           # $t3 = 10*$t3
add $t3, $t3, $t2           # $t3 = 10*高位数字+低位数字
slti $t4, $t3, 31
beq $t4, $zero, reg_display # 如果$s2>31说明高位无效，则直接显示低位表示的寄存器
add $t2, $zero, $t3         # 否则就更新$t2=$t3
reg_display:                # 这个时候$t2就等于要显示的寄存器编号，如果等于0，默认全部显示
addi $t3, $zero, 1
bne $t2, $t3, reg_2
add $a0, $zero, $1          # $a0为16进制码，这里是寄存器reg[1]的值
addi $a1, $zero, 8          # $s1为显示的16进制位数
jal display_num             # 显示reg[1]的内容
reg_2:
addi $t3, $zero, 2
bne $t2, $t3, reg_3
add $a0, $zero, $2          # $a0为16进制码，这里是寄存器reg[2]的值
addi $a1, $zero, 8          # $s1为显示的16进制位数
jal display_num             # 显示reg[2]的内容
reg_3:
addi $t3, $zero, 3
bne $t2, $t3, reg_4
add $a0, $zero, $3          # $a0为16进制码，这里是寄存器reg[3]的值
addi $a1, $zero, 8          # $s1为显示的16进制位数
jal display_num             # 显示reg[3]的内容
reg_4:
addi $t3, $zero, 4
bne $t2, $t3, reg_5
add $a0, $zero, $4          # $a0为16进制码，这里是寄存器reg[4]的值
addi $a1, $zero, 8          # $s1为显示的16进制位数
jal display_num             # 显示reg[4]的内容
reg_5:
addi $t3, $zero, 5
bne $t2, $t3, reg_6
add $a0, $zero, $5          # $a0为16进制码，这里是寄存器reg[5]的值
addi $a1, $zero, 8          # $s1为显示的16进制位数
jal display_num             # 显示reg[5]的内容
reg_6:
addi $t3, $zero, 6
bne $t2, $t3, reg_7
add $a0, $zero, $6          # $a0为16进制码，这里是寄存器reg[6]的值
addi $a1, $zero, 8          # $s1为显示的16进制位数
jal display_num             # 显示reg[6]的内容
reg_7:
addi $t3, $zero, 7
bne $t2, $t3, reg_8
add $a0, $zero, $7          # $a0为16进制码，这里是寄存器reg[7]的值
addi $a1, $zero, 8          # $s1为显示的16进制位数
jal display_num             # 显示reg[7]的内容
reg_8:
addi $t3, $zero, 8
bne $t2, $t3, reg_9
add $a0, $zero, $8          # $a0为16进制码，这里是寄存器reg[8]的值
addi $a1, $zero, 8          # $s1为显示的16进制位数
jal display_num             # 显示reg[8]的内容
reg_9:
addi $t3, $zero, 9
bne $t2, $t3, reg_10
add $a0, $zero, $9          # $a0为16进制码，这里是寄存器reg[9]的值
addi $a1, $zero, 8          # $s1为显示的16进制位数
jal display_num             # 显示reg[9]的内容
reg_10:
addi $t3, $zero, 10
bne $t2, $t3, reg_11
add $a0, $zero, $10         # $a0为16进制码，这里是寄存器reg[10]的值
addi $a1, $zero, 8          # $s1为显示的16进制位数
jal display_num             # 显示reg[10]的内容
reg_11:
addi $t3, $zero, 11
bne $t2, $t3, reg_12
add $a0, $zero, $11         # $a0为16进制码，这里是寄存器reg[11]的值
addi $a1, $zero, 8          # $s1为显示的16进制位数
jal display_num             # 显示reg[11]的内容
reg_12:
addi $t3, $zero, 12
bne $t2, $t3, reg_13
add $a0, $zero, $12         # $a0为16进制码，这里是寄存器reg[12]的值
addi $a1, $zero, 8          # $s1为显示的16进制位数
jal display_num             # 显示reg[12]的内容
reg_13:
addi $t3, $zero, 13
bne $t2, $t3, reg_14
add $a0, $zero, $13         # $a0为16进制码，这里是寄存器reg[13]的值
addi $a1, $zero, 8          # $s1为显示的16进制位数
jal display_num             # 显示reg[13]的内容
reg_14:
addi $t3, $zero, 14
bne $t2, $t3, reg_15
add $a0, $zero, $14         # $a0为16进制码，这里是寄存器reg[14]的值
addi $a1, $zero, 8          # $s1为显示的16进制位数
jal display_num             # 显示reg[14]的内容
reg_15:
addi $t3, $zero, 15
bne $t2, $t3, reg_16
add $a0, $zero, $15         # $a0为16进制码，这里是寄存器reg[15]的值
addi $a1, $zero, 8          # $s1为显示的16进制位数
jal display_num             # 显示reg[15]的内容
reg_16:
addi $t3, $zero, 16
bne $t2, $t3, reg_17
add $a0, $zero, $16         # $a0为16进制码，这里是寄存器reg[16]的值
addi $a1, $zero, 8          # $s1为显示的16进制位数
jal display_num             # 显示reg[16]的内容
reg_17:
addi $t3, $zero, 17
bne $t2, $t3, reg_18
add $a0, $zero, $17         # $a0为16进制码，这里是寄存器reg[17]的值
addi $a1, $zero, 8          # $s1为显示的16进制位数
jal display_num             # 显示reg[17]的内容
reg_18:
addi $t3, $zero, 18
bne $t2, $t3, reg_19
add $a0, $zero, $18         # $a0为16进制码，这里是寄存器reg[18]的值
addi $a1, $zero, 8          # $s1为显示的16进制位数
jal display_num             # 显示reg[18]的内容
reg_19:
addi $t3, $zero, 19
bne $t2, $t3, reg_20
add $a0, $zero, $19         # $a0为16进制码，这里是寄存器reg[19]的值
addi $a1, $zero, 8          # $s1为显示的16进制位数
jal display_num             # 显示reg[19]的内容
reg_20:
addi $t3, $zero, 20
bne $t2, $t3, reg_21
add $a0, $zero, $20         # $a0为16进制码，这里是寄存器reg[20]的值
addi $a1, $zero, 8          # $s1为显示的16进制位数
jal display_num             # 显示reg[20]的内容
reg_21:
addi $t3, $zero, 21
bne $t2, $t3, reg_22
add $a0, $zero, $21         # $a0为16进制码，这里是寄存器reg[21]的值
addi $a1, $zero, 8          # $s1为显示的16进制位数
jal display_num             # 显示reg[21]的内容
reg_22:
addi $t3, $zero, 22
bne $t2, $t3, reg_23
add $a0, $zero, $22         # $a0为16进制码，这里是寄存器reg[22]的值
addi $a1, $zero, 8          # $s1为显示的16进制位数
jal display_num             # 显示reg[22]的内容
reg_23:
addi $t3, $zero, 23
bne $t2, $t3, reg_24
add $a0, $zero, $23         # $a0为16进制码，这里是寄存器reg[23]的值
addi $a1, $zero, 8          # $s1为显示的16进制位数
jal display_num             # 显示reg[23]的内容
reg_24:
addi $t3, $zero, 24
bne $t2, $t3, reg_25
add $a0, $zero, $24         # $a0为16进制码，这里是寄存器reg[24]的值
addi $a1, $zero, 8          # $s1为显示的16进制位数
jal display_num             # 显示reg[24]的内容
reg_25:
addi $t3, $zero, 25
bne $t2, $t3, reg_26
add $a0, $zero, $25         # $a0为16进制码，这里是寄存器reg[25]的值
addi $a1, $zero, 8          # $s1为显示的16进制位数
jal display_num             # 显示reg[25]的内容
reg_26:
addi $t3, $zero, 26
bne $t2, $t3, reg_27
add $a0, $zero, $26         # $a0为16进制码，这里是寄存器reg[26]的值
addi $a1, $zero, 8          # $s1为显示的16进制位数
jal display_num             # 显示reg[26]的内容
reg_27:
addi $t3, $zero, 27
bne $t2, $t3, reg_28
add $a0, $zero, $27         # $a0为16进制码，这里是寄存器reg[27]的值
addi $a1, $zero, 8          # $s1为显示的16进制位数
jal display_num             # 显示reg[27]的内容
reg_28:
addi $t3, $zero, 28
bne $t2, $t3, reg_29
add $a0, $zero, $28         # $a0为16进制码，这里是寄存器reg[28]的值
addi $a1, $zero, 8          # $s1为显示的16进制位数
jal display_num             # 显示reg[28]的内容
reg_29:
addi $t3, $zero, 29
bne $t2, $t3, reg_30
add $a0, $zero, $29         # $a0为16进制码，这里是寄存器reg[29]的值
addi $a1, $zero, 8          # $s1为显示的16进制位数
jal display_num             # 显示reg[29]的内容
reg_30:
addi $t3, $zero, 30
bne $t2, $t3, reg_31
add $a0, $zero, $30         # $a0为16进制码，这里是寄存器reg[30]的值
addi $a1, $zero, 8          # $s1为显示的16进制位数
jal display_num             # 显示reg[30]的内容
reg_31:
addi $t3, $zero, 31
bne $t2, $t3, reg_return    # 如果32个寄存器都不符合，则直接返回
add $a0, $zero, $31         # $a0为16进制码，这里是寄存器reg[31]的值
addi $a1, $zero, 8          # $s1为显示的16进制位数
jal display_num             # 显示reg[31]的内容
reg_return:
lw $a1, 0($sp)
lw $a0, 4($sp)
lw $ra, 8($sp)
addi $sp, $sp, 12
jr $ra


# 读取屏幕上的$a1个16进制数，并存放到$v0返回
# input: $a0=$a1位数后一位的地址，output：$v0:8位16进制数
read_num:
addi $sp, $sp, -4
sw   $ra, 0($sp)
sll $a1, $a1, 2             # 偏移地址
sub $t1, $a0, $a1           # $t1=第一位数字的地址
hex_loop:
lw $s1, 0($t1)              # 取出该地址上的16进制数
ori $t4, $zero, 0x0F30      # 如果$s1不在0~9: 0x0F30-0x0F39，A~F:0x0F41-0x0F46范围内，则返回0
ori $t5, $zero, 0x0F46      # 由于我没有设置其他地址的显示函数，因此这里肯定不会出现0x0F3A~0x0F40
slt $t3, $s1, $t4
bne $t3, $zero, set_null    # 遇到非法字符，则把输出的16进制数清零
slt $t3, $t5, $s1
bne $t3, $zero, set_null
sub $t2, $s1, $t4           # 转化为对应的数值放到$t2里，A~F还需额外减1
slti $t3, $t2, 10
bne $t3, $zero, hex_merge   # 如果$t2<10，则是数字0~9，直接合并到16进制数里
addi $t2, $t2, -7           # 否则，A~F还需额外减7
hex_merge:
sll $v0, $v0, 4             # $v0左移四位
add $v0, $v0, $t2           # $t2补到低4位上
addi $t1, $t1, 4            # 地址移到下一位
bne $t1, $a0, hex_loop      # 如果还没有读完，则继续循环
j hex_return                # 如果读取完毕且正常，则返回调用地址
set_null:
add $v0, $zero, $zero
hex_return:
lw $ra, 0($sp)
addi $sp, $sp, 4
jr $ra

# 用16进制显示指定内存单元数据
# input：8位16进制数，output：屏幕上显示该地址上的数据
display_memory:
addi $sp, $sp, -12
sw $ra, 8($sp)
sw $a0, 4($sp)
sw $a1, 0($sp)
DMEM_0:
addi $t1, $t0, -16          # $t1为$t0前四个字符中第一个字符的地址，一开始用于检测DMEM的"D"
lw $s1, 0($t1)              # 取出$t1地址上的字符
ori $s2, $zero, 0x0F44      # $s2 = 'D'
bne $s1, $s2, mem_return    # 如果第一个字符不是'D'，则直接跳出检测
addi $t1, $t1, 4            # 地址$t1++，检测下一个字符
DMEM_1:
lw $s1, 0($t1)              # 取出$t1地址上的字符
ori $s2, $zero, 0x0F4D      # $s2 = 'M'
bne $s1, $s2, mem_return    # 如果第二个字符不是'M'，则直接跳出检测
addi $t1, $t1, 4            # 地址$t1++，检测下一个字符
DMEM_2:
lw $s1, 0($t1)              # 取出$t1地址上的字符
ori $s2, $zero, 0x0F45      # $s2 = 'E'
bne $s1, $s2, mem_return    # 如果第三个字符不是'E'，则直接跳出检测
addi $t1, $t1, 4            # 地址$t1++，检测下一个字符
DMEM_3:
lw $s1, 0($t1)              # 取出$t1地址上的字符
ori $s2, $zero, 0x0F4D      # $s3 = 'M'
bne $s1, $s2, mem_return    # 如果第四个字符不是'M'，则直接跳出检测
addi $t1, $t1, 4            # 地址$t1++
DMEM:
bne $t1, $t0, mem_return    # 如果前4个字符不是'DMEM'，则直接返回，而不显示任何内容
addi $a0, $t0, -20          # 8位16进制数后一位的地址
addi $a1, $zero, 8
jal read_num                # 读取8位16进制数，返回值为$v0
lw $a0, 0($v0)
# add $a0, $zero, $v0
addi $a1, $zero, 8
jal display_num
mem_return:
lw $a1, 0($sp)
lw $a0, 4($sp)
lw $ra, 8($sp)
addi $sp, $sp, 12
jr $ra

# 二进制转化为十进制，这里限制二进制位数为32位
# 1111 B2H -> 00000015
Bin2Hex:
addi $sp, $sp, -12
sw $ra, 8($sp)
sw $a0, 4($sp)
sw $a1, 0($sp)
B2H_0:
addi $t1, $t0, -12          # $t1为$t0前三个字符中第一个字符的地址，一开始用于检测B2H的"B"
lw $s1, 0($t1)              # 取出$t1地址上的字符
ori $s2, $zero, 0x0F42      # $s2 = 'B'
bne $s1, $s2, B2H_return    # 如果第一个字符不是'B'，则直接跳出检测
addi $t1, $t1, 4            # 地址$t1++，检测下一个字符
B2H_1:
lw $s1, 0($t1)              # 取出$t1地址上的字符
ori $s2, $zero, 0x0F32      # $s2 = '2'
bne $s1, $s2, B2H_return    # 如果第二个字符不是2'，则直接跳出检测
addi $t1, $t1, 4            # 地址$t1++，检测下一个字符
B2H_2:
lw $s1, 0($t1)              # 取出$t1地址上的字符
ori $s2, $zero, 0x0F48      # $s2 = 'H'
bne $s1, $s2, B2H_return    # 如果第三个字符不是'H'，则直接跳出检测
addi $t1, $t1, 4            # 地址$t1++，检测下一个字符
B2H:
bne $t1, $t0, B2H_return    # 如果前三个字符不是'B2H'，则直接返回，而不显示任何内容
add $t1, $zero, $s6         # 以下循环是为了获取当前行行首地址
B2H_addr:
addi $t1, $t1, 320
slt $t3, $t1, $t0
bne $t3, $zero, B2H_addr
addi $t1, $t1, -320         # 此时$t1为该行行首地址
addi $t4, $t0, -16          # $t4为二进制数后面的一位，二进制数地址区间：[$t1, $t4)
add $t2, $zero, $zero       # $t2用于读取二进制数
read_binary:
lw $s1, 0($t1)
ori $t5, $zero, 0x0F30      # $t5=0
ori $t6, $zero, 0x0F31      # $t6=1
slt $t3, $s1, $t5           # 如果$s1不等于0或1，则直接返回，不显示内容
bne $t3, $zero, B2H_return
slt $t3, $t6, $s1
bne $t3, $zero, B2H_return
sub $t3, $s1, $t5           # 读取0或1
sll $t2, $t2, 1             # $t2左移一位
add $t2, $t2, $t3           # $t2低位加上新读取的0或1
addi $t1, $t1, 4            # 地址$t1++
bne $t1, $t4, read_binary   # 如果还没读完，则继续读
# 接下来把$t2当做计数器，来转换成10进制数放到$a0里，实际上就是8位不超过10的16进制数
add $a0, $zero, $zero       # $a0存放10进制数，初始化为0
Dec_next:
beq $t2, $zero, dis_decimal
ori $t5, $zero, 0x000A      # $t5用来判断连续四位是否为10
ori $t6, $zero, 0x000F      # $t6用于取出连续四位，其余位置零
ori $t7, $zero, 0x0010      # $t7用于进位加1
addi $t2, $t2, -1           # 计数器减一
addi $a0, $a0, 1            # $a0++
check_10:
and $t1, $a0, $t6           # 检测是否为10，先取出4bit，其余位置0
xor $t1, $t1, $t5           # 对这4bit与10异或
bne $t1, $zero, Dec_next    # 如果异或后不为0，说明无需进位，跳转回去继续累加
xor $a0, $a0, $t5           # 如果异或后为全0，则该4bit原先是10，将这四位清零并进位
add $a0, $a0, $t7           # 进位到前4bit加1
sll $t5, $t5, 4             # 全部左移四位，继续检测是否有进位
sll $t6, $t6, 4
sll $t7, $t7, 4
j check_10                  # 检测+1后的高四位是否由于等于10而进位
dis_decimal:
addi $a1, $zero, 8
jal display_num
B2H_return:
lw $a1, 0($sp)
lw $a0, 4($sp)
lw $ra, 8($sp)
addi $sp, $sp, 12
jr $ra

# 16进制转2位ASCII码
Hex2ASCII:
addi $sp, $sp, -12
sw $ra, 8($sp)
sw $a0, 4($sp)
sw $a1, 0($sp)
H2A_0:
addi $t1, $t0, -12          # $t1为$t0前三个字符中第一个字符的地址，一开始用于检测H2A的"H"
lw $s1, 0($t1)              # 取出$t1地址上的字符
ori $s2, $zero, 0x0F48      # $s2 = 'H'
bne $s1, $s2, H2A_return    # 如果第一个字符不是'H'，则直接跳出检测
addi $t1, $t1, 4            # 地址$t1++，检测下一个字符
H2A_1:
lw $s1, 0($t1)              # 取出$t1地址上的字符
ori $s2, $zero, 0x0F32      # $s2 = '2'
bne $s1, $s2, H2A_return    # 如果第二个字符不是2'，则直接跳出检测
addi $t1, $t1, 4            # 地址$t1++，检测下一个字符
H2A_2:
lw $s1, 0($t1)              # 取出$t1地址上的字符
ori $s2, $zero, 0x0F41      # $s2 = 'A'
bne $s1, $s2, H2A_return    # 如果第三个字符不是'A'，则直接跳出检测
addi $t1, $t1, 4            # 地址$t1++，检测下一个字符
H2A:
bne $t1, $t0, H2A_return    # 如果前三个字符不是'H2A'，则直接返回，而不显示任何内容
add $t1, $zero, $s6         # 以下循环是为了获取当前行行首地址
H2A_addr:
addi $t1, $t1, 320
slt $t3, $t1, $t0
bne $t3, $zero, H2A_addr
addi $t1, $t1, -320         # 此时$t1为该行行首地址
addi $t5, $t0, -16            # 由于display_num的时候，$t0会变化，因此用一个$t5来保留原先16进制数的末地址
ori $t4, $zero, 0x0F00      # 获取一个常数$t4用于得到ASCII码
dis_ascii:
# slt $t3, $t1, $t5
# beq $t3, $zero, H2A_return
beq $t1, $t5, H2A_return    # 扫描到光标时，转换完毕，返回调用处
lw $s1, 0($t1)
sub $a0, $s1, $t4
sll $a0, $a0, 24            # display_num函数是从高位开始按照$a1指定位数输出的，因此把低两位左移到高两位
addi $a1, $zero, 2          
jal display_num             # 输出两位ASCII码
addi $t1, $t1, 4
j dis_ascii
H2A_return:
lw $a1, 0($sp)
lw $a0, 4($sp)
lw $ra, 8($sp)
addi $sp, $sp, 12
jr $ra
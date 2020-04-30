# 图形显示模式
# 低 12 位为像素点RRRR_GGGG_BBBB，高四位为待定属性,VGA 储存 640*480 点像素，按照从左到右、从上到下的顺序储存在 VRAM_GRAPH 中

# li $s7, 0xFFFFD000
ori $sp, $zero, 0xFFFF      # 先给$sp一个地址，避免溢出
lui $s7, 0xFFFF             # $s7 = 0xFFFFD000 ps2地址
ori $s7, $s7, 0xD000

lui $s6, 0x000C       
ori $s6, $s6, 0x2000        # $s6 = vram_graph = 0x000C2000 vga地址

read_kbd:
lui $s5, 0x8000             # $s5 = 0x80000000 $s5最高位为1，用于取出ps2的ready信号
addi $s4, $zero, 0x00F0     # $s4 = 0x000000F0 ，F0是断码的标志，是所有key的倒数第二个断码
lw $t1, 0($s7)              # $t1 = {1'ps2_ready, 23'h0, 8'key}
and $t2, $t1, $s5           # 取出$t1最高位的ready信号放到$t2上
beq $t2, $zero, read_kbd    # $t2=0表示没有ps2输入，此时跳回去接着读read_kbd
andi $t2, $t1, 0x00FF       # 如果ready=1，取出$t1低八位的通码
beq $t2, $s4, read          # 如果$t2=0x00F0，则说明读到了倒数第二个断码，此时跳到read来显示键盘码
j read_kbd  
read:                       # 读入最后一个断码，也就是key的标识码
lw $t1, 0($s7)              # $t1 = {1'ps2_ready, 23'h0, 8'key}
and $t2, $t1, $s5           # 同理，取出ready信号
beq $t2, $zero, read_kbd    # ready=0，则回去重新读
andi $t2, $t1, 0x00FF       # 否则，取出低八位的断码(标识码)

addi $s1, $zero, 0x16       # $s1 = "1"
ori $a0, $zero, 0x4646     # 给point函数的点坐标参数$a0
beq  $t2, $s1, point        # if $t2 == "1", then display point

addi $s1, $zero, 0x1E       # $s1 = "2"
lui $a0, 0x0AA0             # 直线起点坐标
ori $a0, $a0, 0xBBA0        # 直线终点坐标
beq  $t2, $s1, line         # if $t2 == "2", then display line

addi $s1, $zero, 0x26       # $s1 = "3"
lui $a0, 0x6464             # 矩形左上角坐标
ori $a0, $a0, 0xC8C8        # 矩形右下角坐标
beq  $t2, $s1, rectangle    # if $t2 == "3", then display rectangle

addi $s1, $zero, 0x25       # $s1 = "4"
ori $a0, $zero, 0xC8C8      # 圆心坐标
addi $a1, $zero, 30         # 半径
beq  $t2, $s1, circle       # if $t2 == "4", then display circle
j read_kbd




# 在屏幕指定位置显示一个点，点参数： $a0=0000XXYY
point:
addi $sp, $sp, -20
sw $s1, 0($sp)
sw $s2, 4($sp)
sw $t1, 8($sp)
sw $t2, 12($sp)
sw $s0, 16($sp)
andi $s1, $a0, 0x00FF       # 获取input的y坐标
andi $s2, $a0, 0xFF00       # 获取input的x坐标
srl $s2, $s2, 8    
begin:
add $t0, $zero, $s6         # $t0为全局变量，是当前点的地址，初始化为第一个点的地址
add $t1, $zero, $zero       # $t1表示当前扫描到的y坐标
add $t2, $zero, $zero       # $t2表示当前扫描到的x坐标
loop1:                      # 每一行的遍历
slti $t3, $t1, 480          # 如果$t1=y>480，则整个屏幕都已经遍历完了，结束扫描
beq $t3, $zero, end1        
add $t2, $zero, $zero       # $t2=x重新初始化为当前行的第一个点坐标
loop2:  
slti $t3, $t2, 640          # 如果$t2=x>640，则当前行已经遍历完了，切换到下一行
beq $t3, $zero, end2
bne $t1, $s1, next_point
bne $t2, $s2, next_point 
addi $s0, $zero, 0x0F00     # 给$s0颜色赋值,点为红色
sh $s0, 0($t0)  
addi $t0, $t0, 2            # offset+=2
addi $t2, $t2, 1            # $t2=x++
j loop2 
next_point: 
addi $s0, $zero, 0x00F0     # 给$s0颜色赋值，背景为绿色
# sh $s0, 0($t0)    
addi $t0, $t0, 2            # offset+=2
addi $t2, $t2, 1            # $t2=x++
j loop2 
end2:   
addi $t1, $t1, 1            # $t1=y++
j loop1
end1:
# j begin
lw $s1, 0($sp)
lw $s2, 4($sp)
lw $t1, 8($sp)
lw $t2, 12($sp)
lw $s0, 16($sp)
addi $sp, $sp, 20
jr $ra

# 在屏幕指定位置显示直线。端点参数：$a0=XXYYXXYY
# 注：由于无法实现浮点数除法来计算斜率，因此这里默认使两端的y值相等
line:
addi $sp, $sp, -28
sw $s0, 24($sp)
sw $s1, 20($sp)
sw $s2, 16($sp)
sw $s3, 12($sp)
sw $s4, 8($sp)
sw $t1, 4($sp)
sw $t2, 0($sp)
andi $s3, $a0, 0x00FF       # 获取终点的y坐标
andi $s4, $a0, 0xFF00       # 获取终点的x坐标
srl $s4, $s4, 8     
srl $a0, $a0, 16            # $a0右移16位，读取起点坐标
andi $s1, $a0, 0x00FF       # 获取起点的y坐标
andi $s2, $a0, 0xFF00       # 获取起点的x坐标
srl $s2, $s2, 8 
line_begin: 
add $t0, $zero, $s6         # $t0为全局变量，是当前点的地址，初始化为第一个点的地址
add $t1, $zero, $zero       # $t1表示当前扫描到的y坐标
add $t2, $zero, $zero       # $t2表示当前扫描到的x坐标
line_loop_y:                # 每一行的遍历
slti $t3, $t1, 480          # 如果$t1=y>480，则整个屏幕都已经遍历完了，结束扫描
beq $t3, $zero, line_end_y    
add $t2, $zero, $zero       # $t2=x重新初始化为当前行的第一个点坐标
line_loop_x:
slti $t3, $t2, 640          # 如果$t2=x>640，则当前行已经遍历完了，切换到下一行
beq $t3, $zero, line_end_x
bne $t1, $s1, line_next     # 如果y和目标直线不在同一行，则不显示颜色   
slt $t3, $t2, $s2           # 如果x小于起点的横坐标，则不显示颜色
bne $t3, $zero, line_next  
slt $t3, $s4, $t2           # 如果x大于终点的横坐标，则不显示颜色
bne $t3, $zero, line_next
addi $s0, $zero, 0x0F00     # 给$s0颜色赋值,点为红色
sh $s0, 0($t0)
addi $t0, $t0, 2            # offset+=2
addi $t2, $t2, 1            # $t2=x++
j line_loop_x
line_next:
addi $s0, $zero, 0x00F0   # 给$s0颜色赋值，背景为绿色
sh $s0, 0($t0)
addi $t0, $t0, 2            # offset+=2
addi $t2, $t2, 1            # $t2=x++
j line_loop_x   
line_end_x: 
addi $t1, $t1, 1            # $t1=y++
j line_loop_y
line_end_y:
# j begin
lw $t2, 0($sp)
lw $t1, 4($sp)
lw $s4, 8($sp)
lw $s3, 12($sp)
lw $s2, 16($sp)
lw $s1, 20($sp)
lw $s0, 24($sp)
addi $sp, $sp, 28
jr $ra

# 在屏幕指定位置显示四边形。端点参数：$a0=XXYYXXYY
rectangle:
addi $sp, $sp, -28
sw $s0, 24($sp)
sw $s1, 20($sp)
sw $s2, 16($sp)
sw $s3, 12($sp)
sw $s4, 8($sp)
sw $t1, 4($sp)
sw $t2, 0($sp)
andi $s3, $a0, 0x00FF       # 获取右下角的y坐标
andi $s4, $a0, 0xFF00       # 获取右下角的x坐标
srl $s4, $s4, 8     
srl $a0, $a0, 16            # $a0右移16位，读取左上角坐标
andi $s1, $a0, 0x00FF       # 获取左上角的y坐标
andi $s2, $a0, 0xFF00       # 获取左上角的x坐标
srl $s2, $s2, 8 
rec_begin: 
add $t0, $zero, $s6         # $t0为全局变量，是当前点的地址，初始化为第一个点的地址
add $t1, $zero, $zero       # $t1表示当前扫描到的y坐标
add $t2, $zero, $zero       # $t2表示当前扫描到的x坐标
rec_loop_y:                 # 每一行的遍历
slti $t3, $t1, 480          # 如果$t1=y>480，则整个屏幕都已经遍历完了，结束扫描
beq $t3, $zero, rec_end_y    
add $t2, $zero, $zero       # $t2=x重新初始化为当前行的第一个点坐标
rec_loop_x:
slti $t3, $t2, 640          # 如果$t2=x>640，则当前行已经遍历完了，切换到下一行
beq $t3, $zero, rec_end_x
slt $t3, $t1, $s1           # 如果y在矩形上方，则不显示颜色
bne $t3, $zero, rec_next       
slt $t3, $s3, $t1           # 如果y在矩形下方，则不显示颜色
bne $t3, $zero, rec_next    
slt $t3, $t2, $s2           # 如果x在矩形左侧，则不显示颜色
bne $t3, $zero, rec_next  
slt $t3, $s4, $t2           # 如果x在矩形右侧，则不显示颜色
bne $t3, $zero, rec_next
addi $s0, $zero, 0x0F00     # 给$s0颜色赋值,点为红色
sh $s0, 0($t0)
addi $t0, $t0, 2            # offset+=2
addi $t2, $t2, 1            # $t2=x++
j rec_loop_x
rec_next:
addi $s0, $zero, 0x00F0     # 给$s0颜色赋值，背景为绿色
sh $s0, 0($t0)
addi $t0, $t0, 2            # offset+=2
addi $t2, $t2, 1            # $t2=x++
j rec_loop_x   
rec_end_x: 
addi $t1, $t1, 1            # $t1=y++
j rec_loop_y
rec_end_y:
# j begin
lw $t2, 0($sp)
lw $t1, 4($sp)
lw $s4, 8($sp)
lw $s3, 12($sp)
lw $s2, 16($sp)
lw $s1, 20($sp)
lw $s0, 24($sp)
addi $sp, $sp, 28
jr $ra

# 在屏幕指定位置画圆(圆心：$a0=0000XXYY，半径$a1)*
circle:
addi $sp, $sp, -20
sw $s1, 0($sp)
sw $s2, 4($sp)
sw $t1, 8($sp)
sw $t2, 12($sp)
sw $s0, 16($sp)
andi $s1, $a0, 0x00FF       # 获取圆心的y坐标
andi $s2, $a0, 0xFF00       # 获取圆心的x坐标
srl $s2, $s2, 8    
circle_begin:
add $t0, $zero, $s6         # $t0为全局变量，是当前点的地址，初始化为第一个点的地址
add $t1, $zero, $zero       # $t1表示当前扫描到的y坐标
add $t2, $zero, $zero       # $t2表示当前扫描到的x坐标
circle_loop_y:              # 每一行的遍历
slti $t3, $t1, 480          # 如果$t1=y>480，则整个屏幕都已经遍历完了，结束扫描
beq $t3, $zero, circle_end_y        
add $t2, $zero, $zero       # $t2=x重新初始化为当前行的第一个点坐标
circle_loop_x:  
slti $t3, $t2, 640          # 如果$t2=x>640，则当前行已经遍历完了，切换到下一行
beq $t3, $zero, circle_end_x

sub $t5, $s1, $t1           # 获取当前点与圆心的纵坐标之差$t5=δy
sub $t4, $s2, $t2           # 获取当前点与圆心的横坐标之差$t4=δx
mult $t5, $t5			    # $t5 * $t5 = Hi and Lo registers
mflo $s5					# copy Lo to $s5
mult $t4, $t4			    # $t4 * $t4 = Hi and Lo registers
mflo $s4					# copy Lo to $s4
mult $a1, $a1			    # $a1 * $a1 = Hi and Lo registers
mflo $s3					# copy Lo to $s3
add $t3, $s4, $s5           # $t3 = (δx)^2 + (δy)^2
slt $t3, $t3, $s3           # if (δx)^2 + (δy)^2 < r^2, then draw pixel
beq $t3, $zero, circle_next
addi $s0, $zero, 0x0F00     # 给$s0颜色赋值,点为红色
sh $s0, 0($t0)  
addi $t0, $t0, 2            # offset+=2
addi $t2, $t2, 1            # $t2=x++
j circle_loop_x 
circle_next: 
addi $s0, $zero, 0x00F0     # 给$s0颜色赋值，背景为绿色
sh $s0, 0($t0)    
addi $t0, $t0, 2            # offset+=2
addi $t2, $t2, 1            # $t2=x++
j circle_loop_x 
circle_end_x:   
addi $t1, $t1, 1            # $t1=y++
j circle_loop_y
circle_end_y:
# j begin
lw $s1, 0($sp)
lw $s2, 4($sp)
lw $t1, 8($sp)
lw $t2, 12($sp)
lw $s0, 16($sp)
addi $sp, $sp, 20
jr $ra
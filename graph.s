# 图形显示模式
# 低 12 位为像素点RRRR_GGGG_BBBB，高四位为待定属性,VGA 储存 640*480 点像素，按照从左到右、从上到下的顺序储存在 VRAM_GRAPH 中

# li $s7, 0xFFFFD000
lui $s7, 0xFFFF         # $s7 = 0xFFFFD000 ps2地址
ori $s7, $s7, 0xD000

lui $s6, 0x000C       
ori $s6, $s6, 0x2000    # $s6 = vram_graph = 0x000C2000 vga地址

# init:
# add $t0, $zero, $s6     # $t0为全局变量，是当前点的地址，初始化为第一个点的地址

addi $a0, $zero, 0x4646

# 在屏幕指定位置显示一个点，点参数： $a0=0000XXYY
point:
andi $s1, $a0, 0x00FF    # 获取input的y坐标
andi $s2, $a0, 0xFF00    # 获取input的x坐标
srl $s2, $s2, 8    
begin:
add $t0, $zero, $s6     # $t0为全局变量，是当前点的地址，初始化为第一个点的地址
add $t1, $zero, $zero   # $t1表示当前扫描到的y坐标
add $t2, $zero, $zero   # $t2表示当前扫描到的x坐标
loop1:                  # 每一行的遍历
slti $t3, $t1, 480      # 如果$t1=y>480，则整个屏幕都已经遍历完了，结束扫描
beq $t3, $zero, end1    
add $t2, $zero, $zero   # $t2=x重新初始化为当前行的第一个点坐标
loop2:
slti $t3, $t2, 640      # 如果$t2=x>640，则当前行已经遍历完了，切换到下一行
beq $t3, $zero, end2

slt $t3, $t1, $s1 
beq $t3, $zero, next_point
slt $t3, $t2, $s2
beq $t3, $zero, next_point
addi $s0, $zero, 0x00F0 # 给$s0颜色赋值
sh $s0, 0($t0)
addi $t0, $t0, 2        # offset+=2
addi $t2, $t2, 1        # $t2=x++
j loop2
next_point:
addi $s0, $zero, 0x000F # 给$s0颜色赋值
sh $s0, 0($t0)
addi $t0, $t0, 2        # offset+=2
addi $t2, $t2, 1        # $t2=x++
j loop2

end2:
addi $t1, $t1, 1        # $t1=y++
j loop1

end1:
j begin

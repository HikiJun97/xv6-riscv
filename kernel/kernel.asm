
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	a3010113          	addi	sp,sp,-1488 # 80008a30 <stack0>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	074000ef          	jal	ra,8000008a <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007859b          	sext.w	a1,a5

  // ask the CLINT for a timer interrupt.
  int interval = 100000; // cycles; about 1/100th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873703          	ld	a4,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	6661                	lui	a2,0x18
    8000003e:	6a060613          	addi	a2,a2,1696 # 186a0 <_entry-0x7ffe7960>
    80000042:	9732                	add	a4,a4,a2
    80000044:	e398                	sd	a4,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000046:	00259693          	slli	a3,a1,0x2
    8000004a:	96ae                	add	a3,a3,a1
    8000004c:	068e                	slli	a3,a3,0x3
    8000004e:	00009717          	auipc	a4,0x9
    80000052:	8a270713          	addi	a4,a4,-1886 # 800088f0 <timer_scratch>
    80000056:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    80000058:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005a:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    8000005c:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000060:	00006797          	auipc	a5,0x6
    80000064:	ad078793          	addi	a5,a5,-1328 # 80005b30 <timervec>
    80000068:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000006c:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000070:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000074:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    80000078:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    8000007c:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000080:	30479073          	csrw	mie,a5
}
    80000084:	6422                	ld	s0,8(sp)
    80000086:	0141                	addi	sp,sp,16
    80000088:	8082                	ret

000000008000008a <start>:
{
    8000008a:	1141                	addi	sp,sp,-16
    8000008c:	e406                	sd	ra,8(sp)
    8000008e:	e022                	sd	s0,0(sp)
    80000090:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000092:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    80000096:	7779                	lui	a4,0xffffe
    80000098:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdca9f>
    8000009c:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    8000009e:	6705                	lui	a4,0x1
    800000a0:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a4:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a6:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000aa:	00001797          	auipc	a5,0x1
    800000ae:	dc678793          	addi	a5,a5,-570 # 80000e70 <main>
    800000b2:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000b6:	4781                	li	a5,0
    800000b8:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000bc:	67c1                	lui	a5,0x10
    800000be:	17fd                	addi	a5,a5,-1 # ffff <_entry-0x7fff0001>
    800000c0:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c4:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000c8:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000cc:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d0:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d4:	57fd                	li	a5,-1
    800000d6:	83a9                	srli	a5,a5,0xa
    800000d8:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000dc:	47bd                	li	a5,15
    800000de:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e2:	00000097          	auipc	ra,0x0
    800000e6:	f3a080e7          	jalr	-198(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ea:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000ee:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f0:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f2:	30200073          	mret
}
    800000f6:	60a2                	ld	ra,8(sp)
    800000f8:	6402                	ld	s0,0(sp)
    800000fa:	0141                	addi	sp,sp,16
    800000fc:	8082                	ret

00000000800000fe <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    800000fe:	715d                	addi	sp,sp,-80
    80000100:	e486                	sd	ra,72(sp)
    80000102:	e0a2                	sd	s0,64(sp)
    80000104:	fc26                	sd	s1,56(sp)
    80000106:	f84a                	sd	s2,48(sp)
    80000108:	f44e                	sd	s3,40(sp)
    8000010a:	f052                	sd	s4,32(sp)
    8000010c:	ec56                	sd	s5,24(sp)
    8000010e:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000110:	04c05763          	blez	a2,8000015e <consolewrite+0x60>
    80000114:	8a2a                	mv	s4,a0
    80000116:	84ae                	mv	s1,a1
    80000118:	89b2                	mv	s3,a2
    8000011a:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    8000011c:	5afd                	li	s5,-1
    8000011e:	4685                	li	a3,1
    80000120:	8626                	mv	a2,s1
    80000122:	85d2                	mv	a1,s4
    80000124:	fbf40513          	addi	a0,s0,-65
    80000128:	00002097          	auipc	ra,0x2
    8000012c:	372080e7          	jalr	882(ra) # 8000249a <either_copyin>
    80000130:	01550d63          	beq	a0,s5,8000014a <consolewrite+0x4c>
      break;
    uartputc(c);
    80000134:	fbf44503          	lbu	a0,-65(s0)
    80000138:	00000097          	auipc	ra,0x0
    8000013c:	780080e7          	jalr	1920(ra) # 800008b8 <uartputc>
  for(i = 0; i < n; i++){
    80000140:	2905                	addiw	s2,s2,1
    80000142:	0485                	addi	s1,s1,1
    80000144:	fd299de3          	bne	s3,s2,8000011e <consolewrite+0x20>
    80000148:	894e                	mv	s2,s3
  }

  return i;
}
    8000014a:	854a                	mv	a0,s2
    8000014c:	60a6                	ld	ra,72(sp)
    8000014e:	6406                	ld	s0,64(sp)
    80000150:	74e2                	ld	s1,56(sp)
    80000152:	7942                	ld	s2,48(sp)
    80000154:	79a2                	ld	s3,40(sp)
    80000156:	7a02                	ld	s4,32(sp)
    80000158:	6ae2                	ld	s5,24(sp)
    8000015a:	6161                	addi	sp,sp,80
    8000015c:	8082                	ret
  for(i = 0; i < n; i++){
    8000015e:	4901                	li	s2,0
    80000160:	b7ed                	j	8000014a <consolewrite+0x4c>

0000000080000162 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000162:	711d                	addi	sp,sp,-96
    80000164:	ec86                	sd	ra,88(sp)
    80000166:	e8a2                	sd	s0,80(sp)
    80000168:	e4a6                	sd	s1,72(sp)
    8000016a:	e0ca                	sd	s2,64(sp)
    8000016c:	fc4e                	sd	s3,56(sp)
    8000016e:	f852                	sd	s4,48(sp)
    80000170:	f456                	sd	s5,40(sp)
    80000172:	f05a                	sd	s6,32(sp)
    80000174:	ec5e                	sd	s7,24(sp)
    80000176:	1080                	addi	s0,sp,96
    80000178:	8aaa                	mv	s5,a0
    8000017a:	8a2e                	mv	s4,a1
    8000017c:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    8000017e:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    80000182:	00011517          	auipc	a0,0x11
    80000186:	8ae50513          	addi	a0,a0,-1874 # 80010a30 <cons>
    8000018a:	00001097          	auipc	ra,0x1
    8000018e:	a46080e7          	jalr	-1466(ra) # 80000bd0 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    80000192:	00011497          	auipc	s1,0x11
    80000196:	89e48493          	addi	s1,s1,-1890 # 80010a30 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    8000019a:	00011917          	auipc	s2,0x11
    8000019e:	92e90913          	addi	s2,s2,-1746 # 80010ac8 <cons+0x98>
  while(n > 0){
    800001a2:	09305263          	blez	s3,80000226 <consoleread+0xc4>
    while(cons.r == cons.w){
    800001a6:	0984a783          	lw	a5,152(s1)
    800001aa:	09c4a703          	lw	a4,156(s1)
    800001ae:	02f71763          	bne	a4,a5,800001dc <consoleread+0x7a>
      if(killed(myproc())){
    800001b2:	00001097          	auipc	ra,0x1
    800001b6:	7e2080e7          	jalr	2018(ra) # 80001994 <myproc>
    800001ba:	00002097          	auipc	ra,0x2
    800001be:	12a080e7          	jalr	298(ra) # 800022e4 <killed>
    800001c2:	ed2d                	bnez	a0,8000023c <consoleread+0xda>
      sleep(&cons.r, &cons.lock);
    800001c4:	85a6                	mv	a1,s1
    800001c6:	854a                	mv	a0,s2
    800001c8:	00002097          	auipc	ra,0x2
    800001cc:	e74080e7          	jalr	-396(ra) # 8000203c <sleep>
    while(cons.r == cons.w){
    800001d0:	0984a783          	lw	a5,152(s1)
    800001d4:	09c4a703          	lw	a4,156(s1)
    800001d8:	fcf70de3          	beq	a4,a5,800001b2 <consoleread+0x50>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001dc:	00011717          	auipc	a4,0x11
    800001e0:	85470713          	addi	a4,a4,-1964 # 80010a30 <cons>
    800001e4:	0017869b          	addiw	a3,a5,1
    800001e8:	08d72c23          	sw	a3,152(a4)
    800001ec:	07f7f693          	andi	a3,a5,127
    800001f0:	9736                	add	a4,a4,a3
    800001f2:	01874703          	lbu	a4,24(a4)
    800001f6:	00070b9b          	sext.w	s7,a4

    if(c == C('D')){  // end-of-file
    800001fa:	4691                	li	a3,4
    800001fc:	06db8463          	beq	s7,a3,80000264 <consoleread+0x102>
      }
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    80000200:	fae407a3          	sb	a4,-81(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000204:	4685                	li	a3,1
    80000206:	faf40613          	addi	a2,s0,-81
    8000020a:	85d2                	mv	a1,s4
    8000020c:	8556                	mv	a0,s5
    8000020e:	00002097          	auipc	ra,0x2
    80000212:	236080e7          	jalr	566(ra) # 80002444 <either_copyout>
    80000216:	57fd                	li	a5,-1
    80000218:	00f50763          	beq	a0,a5,80000226 <consoleread+0xc4>
      break;

    dst++;
    8000021c:	0a05                	addi	s4,s4,1
    --n;
    8000021e:	39fd                	addiw	s3,s3,-1

    if(c == '\n'){
    80000220:	47a9                	li	a5,10
    80000222:	f8fb90e3          	bne	s7,a5,800001a2 <consoleread+0x40>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000226:	00011517          	auipc	a0,0x11
    8000022a:	80a50513          	addi	a0,a0,-2038 # 80010a30 <cons>
    8000022e:	00001097          	auipc	ra,0x1
    80000232:	a56080e7          	jalr	-1450(ra) # 80000c84 <release>

  return target - n;
    80000236:	413b053b          	subw	a0,s6,s3
    8000023a:	a811                	j	8000024e <consoleread+0xec>
        release(&cons.lock);
    8000023c:	00010517          	auipc	a0,0x10
    80000240:	7f450513          	addi	a0,a0,2036 # 80010a30 <cons>
    80000244:	00001097          	auipc	ra,0x1
    80000248:	a40080e7          	jalr	-1472(ra) # 80000c84 <release>
        return -1;
    8000024c:	557d                	li	a0,-1
}
    8000024e:	60e6                	ld	ra,88(sp)
    80000250:	6446                	ld	s0,80(sp)
    80000252:	64a6                	ld	s1,72(sp)
    80000254:	6906                	ld	s2,64(sp)
    80000256:	79e2                	ld	s3,56(sp)
    80000258:	7a42                	ld	s4,48(sp)
    8000025a:	7aa2                	ld	s5,40(sp)
    8000025c:	7b02                	ld	s6,32(sp)
    8000025e:	6be2                	ld	s7,24(sp)
    80000260:	6125                	addi	sp,sp,96
    80000262:	8082                	ret
      if(n < target){
    80000264:	0009871b          	sext.w	a4,s3
    80000268:	fb677fe3          	bgeu	a4,s6,80000226 <consoleread+0xc4>
        cons.r--;
    8000026c:	00011717          	auipc	a4,0x11
    80000270:	84f72e23          	sw	a5,-1956(a4) # 80010ac8 <cons+0x98>
    80000274:	bf4d                	j	80000226 <consoleread+0xc4>

0000000080000276 <consputc>:
{
    80000276:	1141                	addi	sp,sp,-16
    80000278:	e406                	sd	ra,8(sp)
    8000027a:	e022                	sd	s0,0(sp)
    8000027c:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    8000027e:	10000793          	li	a5,256
    80000282:	00f50a63          	beq	a0,a5,80000296 <consputc+0x20>
    uartputc_sync(c);
    80000286:	00000097          	auipc	ra,0x0
    8000028a:	560080e7          	jalr	1376(ra) # 800007e6 <uartputc_sync>
}
    8000028e:	60a2                	ld	ra,8(sp)
    80000290:	6402                	ld	s0,0(sp)
    80000292:	0141                	addi	sp,sp,16
    80000294:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    80000296:	4521                	li	a0,8
    80000298:	00000097          	auipc	ra,0x0
    8000029c:	54e080e7          	jalr	1358(ra) # 800007e6 <uartputc_sync>
    800002a0:	02000513          	li	a0,32
    800002a4:	00000097          	auipc	ra,0x0
    800002a8:	542080e7          	jalr	1346(ra) # 800007e6 <uartputc_sync>
    800002ac:	4521                	li	a0,8
    800002ae:	00000097          	auipc	ra,0x0
    800002b2:	538080e7          	jalr	1336(ra) # 800007e6 <uartputc_sync>
    800002b6:	bfe1                	j	8000028e <consputc+0x18>

00000000800002b8 <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002b8:	1101                	addi	sp,sp,-32
    800002ba:	ec06                	sd	ra,24(sp)
    800002bc:	e822                	sd	s0,16(sp)
    800002be:	e426                	sd	s1,8(sp)
    800002c0:	e04a                	sd	s2,0(sp)
    800002c2:	1000                	addi	s0,sp,32
    800002c4:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002c6:	00010517          	auipc	a0,0x10
    800002ca:	76a50513          	addi	a0,a0,1898 # 80010a30 <cons>
    800002ce:	00001097          	auipc	ra,0x1
    800002d2:	902080e7          	jalr	-1790(ra) # 80000bd0 <acquire>

  switch(c){
    800002d6:	47d5                	li	a5,21
    800002d8:	0af48663          	beq	s1,a5,80000384 <consoleintr+0xcc>
    800002dc:	0297ca63          	blt	a5,s1,80000310 <consoleintr+0x58>
    800002e0:	47a1                	li	a5,8
    800002e2:	0ef48763          	beq	s1,a5,800003d0 <consoleintr+0x118>
    800002e6:	47c1                	li	a5,16
    800002e8:	10f49a63          	bne	s1,a5,800003fc <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002ec:	00002097          	auipc	ra,0x2
    800002f0:	204080e7          	jalr	516(ra) # 800024f0 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002f4:	00010517          	auipc	a0,0x10
    800002f8:	73c50513          	addi	a0,a0,1852 # 80010a30 <cons>
    800002fc:	00001097          	auipc	ra,0x1
    80000300:	988080e7          	jalr	-1656(ra) # 80000c84 <release>
}
    80000304:	60e2                	ld	ra,24(sp)
    80000306:	6442                	ld	s0,16(sp)
    80000308:	64a2                	ld	s1,8(sp)
    8000030a:	6902                	ld	s2,0(sp)
    8000030c:	6105                	addi	sp,sp,32
    8000030e:	8082                	ret
  switch(c){
    80000310:	07f00793          	li	a5,127
    80000314:	0af48e63          	beq	s1,a5,800003d0 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000318:	00010717          	auipc	a4,0x10
    8000031c:	71870713          	addi	a4,a4,1816 # 80010a30 <cons>
    80000320:	0a072783          	lw	a5,160(a4)
    80000324:	09872703          	lw	a4,152(a4)
    80000328:	9f99                	subw	a5,a5,a4
    8000032a:	07f00713          	li	a4,127
    8000032e:	fcf763e3          	bltu	a4,a5,800002f4 <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000332:	47b5                	li	a5,13
    80000334:	0cf48763          	beq	s1,a5,80000402 <consoleintr+0x14a>
      consputc(c);
    80000338:	8526                	mv	a0,s1
    8000033a:	00000097          	auipc	ra,0x0
    8000033e:	f3c080e7          	jalr	-196(ra) # 80000276 <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000342:	00010797          	auipc	a5,0x10
    80000346:	6ee78793          	addi	a5,a5,1774 # 80010a30 <cons>
    8000034a:	0a07a683          	lw	a3,160(a5)
    8000034e:	0016871b          	addiw	a4,a3,1
    80000352:	0007061b          	sext.w	a2,a4
    80000356:	0ae7a023          	sw	a4,160(a5)
    8000035a:	07f6f693          	andi	a3,a3,127
    8000035e:	97b6                	add	a5,a5,a3
    80000360:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    80000364:	47a9                	li	a5,10
    80000366:	0cf48563          	beq	s1,a5,80000430 <consoleintr+0x178>
    8000036a:	4791                	li	a5,4
    8000036c:	0cf48263          	beq	s1,a5,80000430 <consoleintr+0x178>
    80000370:	00010797          	auipc	a5,0x10
    80000374:	7587a783          	lw	a5,1880(a5) # 80010ac8 <cons+0x98>
    80000378:	9f1d                	subw	a4,a4,a5
    8000037a:	08000793          	li	a5,128
    8000037e:	f6f71be3          	bne	a4,a5,800002f4 <consoleintr+0x3c>
    80000382:	a07d                	j	80000430 <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000384:	00010717          	auipc	a4,0x10
    80000388:	6ac70713          	addi	a4,a4,1708 # 80010a30 <cons>
    8000038c:	0a072783          	lw	a5,160(a4)
    80000390:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    80000394:	00010497          	auipc	s1,0x10
    80000398:	69c48493          	addi	s1,s1,1692 # 80010a30 <cons>
    while(cons.e != cons.w &&
    8000039c:	4929                	li	s2,10
    8000039e:	f4f70be3          	beq	a4,a5,800002f4 <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003a2:	37fd                	addiw	a5,a5,-1
    800003a4:	07f7f713          	andi	a4,a5,127
    800003a8:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003aa:	01874703          	lbu	a4,24(a4)
    800003ae:	f52703e3          	beq	a4,s2,800002f4 <consoleintr+0x3c>
      cons.e--;
    800003b2:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003b6:	10000513          	li	a0,256
    800003ba:	00000097          	auipc	ra,0x0
    800003be:	ebc080e7          	jalr	-324(ra) # 80000276 <consputc>
    while(cons.e != cons.w &&
    800003c2:	0a04a783          	lw	a5,160(s1)
    800003c6:	09c4a703          	lw	a4,156(s1)
    800003ca:	fcf71ce3          	bne	a4,a5,800003a2 <consoleintr+0xea>
    800003ce:	b71d                	j	800002f4 <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d0:	00010717          	auipc	a4,0x10
    800003d4:	66070713          	addi	a4,a4,1632 # 80010a30 <cons>
    800003d8:	0a072783          	lw	a5,160(a4)
    800003dc:	09c72703          	lw	a4,156(a4)
    800003e0:	f0f70ae3          	beq	a4,a5,800002f4 <consoleintr+0x3c>
      cons.e--;
    800003e4:	37fd                	addiw	a5,a5,-1
    800003e6:	00010717          	auipc	a4,0x10
    800003ea:	6ef72523          	sw	a5,1770(a4) # 80010ad0 <cons+0xa0>
      consputc(BACKSPACE);
    800003ee:	10000513          	li	a0,256
    800003f2:	00000097          	auipc	ra,0x0
    800003f6:	e84080e7          	jalr	-380(ra) # 80000276 <consputc>
    800003fa:	bded                	j	800002f4 <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    800003fc:	ee048ce3          	beqz	s1,800002f4 <consoleintr+0x3c>
    80000400:	bf21                	j	80000318 <consoleintr+0x60>
      consputc(c);
    80000402:	4529                	li	a0,10
    80000404:	00000097          	auipc	ra,0x0
    80000408:	e72080e7          	jalr	-398(ra) # 80000276 <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    8000040c:	00010797          	auipc	a5,0x10
    80000410:	62478793          	addi	a5,a5,1572 # 80010a30 <cons>
    80000414:	0a07a703          	lw	a4,160(a5)
    80000418:	0017069b          	addiw	a3,a4,1
    8000041c:	0006861b          	sext.w	a2,a3
    80000420:	0ad7a023          	sw	a3,160(a5)
    80000424:	07f77713          	andi	a4,a4,127
    80000428:	97ba                	add	a5,a5,a4
    8000042a:	4729                	li	a4,10
    8000042c:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000430:	00010797          	auipc	a5,0x10
    80000434:	68c7ae23          	sw	a2,1692(a5) # 80010acc <cons+0x9c>
        wakeup(&cons.r);
    80000438:	00010517          	auipc	a0,0x10
    8000043c:	69050513          	addi	a0,a0,1680 # 80010ac8 <cons+0x98>
    80000440:	00002097          	auipc	ra,0x2
    80000444:	c60080e7          	jalr	-928(ra) # 800020a0 <wakeup>
    80000448:	b575                	j	800002f4 <consoleintr+0x3c>

000000008000044a <consoleinit>:

void
consoleinit(void)
{
    8000044a:	1141                	addi	sp,sp,-16
    8000044c:	e406                	sd	ra,8(sp)
    8000044e:	e022                	sd	s0,0(sp)
    80000450:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000452:	00008597          	auipc	a1,0x8
    80000456:	bbe58593          	addi	a1,a1,-1090 # 80008010 <etext+0x10>
    8000045a:	00010517          	auipc	a0,0x10
    8000045e:	5d650513          	addi	a0,a0,1494 # 80010a30 <cons>
    80000462:	00000097          	auipc	ra,0x0
    80000466:	6de080e7          	jalr	1758(ra) # 80000b40 <initlock>

  uartinit();
    8000046a:	00000097          	auipc	ra,0x0
    8000046e:	32c080e7          	jalr	812(ra) # 80000796 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000472:	00020797          	auipc	a5,0x20
    80000476:	75678793          	addi	a5,a5,1878 # 80020bc8 <devsw>
    8000047a:	00000717          	auipc	a4,0x0
    8000047e:	ce870713          	addi	a4,a4,-792 # 80000162 <consoleread>
    80000482:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    80000484:	00000717          	auipc	a4,0x0
    80000488:	c7a70713          	addi	a4,a4,-902 # 800000fe <consolewrite>
    8000048c:	ef98                	sd	a4,24(a5)
}
    8000048e:	60a2                	ld	ra,8(sp)
    80000490:	6402                	ld	s0,0(sp)
    80000492:	0141                	addi	sp,sp,16
    80000494:	8082                	ret

0000000080000496 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    80000496:	7179                	addi	sp,sp,-48
    80000498:	f406                	sd	ra,40(sp)
    8000049a:	f022                	sd	s0,32(sp)
    8000049c:	ec26                	sd	s1,24(sp)
    8000049e:	e84a                	sd	s2,16(sp)
    800004a0:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a2:	c219                	beqz	a2,800004a8 <printint+0x12>
    800004a4:	08054763          	bltz	a0,80000532 <printint+0x9c>
    x = -xx;
  else
    x = xx;
    800004a8:	2501                	sext.w	a0,a0
    800004aa:	4881                	li	a7,0
    800004ac:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b0:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b2:	2581                	sext.w	a1,a1
    800004b4:	00008617          	auipc	a2,0x8
    800004b8:	b8c60613          	addi	a2,a2,-1140 # 80008040 <digits>
    800004bc:	883a                	mv	a6,a4
    800004be:	2705                	addiw	a4,a4,1
    800004c0:	02b577bb          	remuw	a5,a0,a1
    800004c4:	1782                	slli	a5,a5,0x20
    800004c6:	9381                	srli	a5,a5,0x20
    800004c8:	97b2                	add	a5,a5,a2
    800004ca:	0007c783          	lbu	a5,0(a5)
    800004ce:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d2:	0005079b          	sext.w	a5,a0
    800004d6:	02b5553b          	divuw	a0,a0,a1
    800004da:	0685                	addi	a3,a3,1
    800004dc:	feb7f0e3          	bgeu	a5,a1,800004bc <printint+0x26>

  if(sign)
    800004e0:	00088c63          	beqz	a7,800004f8 <printint+0x62>
    buf[i++] = '-';
    800004e4:	fe070793          	addi	a5,a4,-32
    800004e8:	00878733          	add	a4,a5,s0
    800004ec:	02d00793          	li	a5,45
    800004f0:	fef70823          	sb	a5,-16(a4)
    800004f4:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004f8:	02e05763          	blez	a4,80000526 <printint+0x90>
    800004fc:	fd040793          	addi	a5,s0,-48
    80000500:	00e784b3          	add	s1,a5,a4
    80000504:	fff78913          	addi	s2,a5,-1
    80000508:	993a                	add	s2,s2,a4
    8000050a:	377d                	addiw	a4,a4,-1
    8000050c:	1702                	slli	a4,a4,0x20
    8000050e:	9301                	srli	a4,a4,0x20
    80000510:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000514:	fff4c503          	lbu	a0,-1(s1)
    80000518:	00000097          	auipc	ra,0x0
    8000051c:	d5e080e7          	jalr	-674(ra) # 80000276 <consputc>
  while(--i >= 0)
    80000520:	14fd                	addi	s1,s1,-1
    80000522:	ff2499e3          	bne	s1,s2,80000514 <printint+0x7e>
}
    80000526:	70a2                	ld	ra,40(sp)
    80000528:	7402                	ld	s0,32(sp)
    8000052a:	64e2                	ld	s1,24(sp)
    8000052c:	6942                	ld	s2,16(sp)
    8000052e:	6145                	addi	sp,sp,48
    80000530:	8082                	ret
    x = -xx;
    80000532:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    80000536:	4885                	li	a7,1
    x = -xx;
    80000538:	bf95                	j	800004ac <printint+0x16>

000000008000053a <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000053a:	1101                	addi	sp,sp,-32
    8000053c:	ec06                	sd	ra,24(sp)
    8000053e:	e822                	sd	s0,16(sp)
    80000540:	e426                	sd	s1,8(sp)
    80000542:	1000                	addi	s0,sp,32
    80000544:	84aa                	mv	s1,a0
  pr.locking = 0;
    80000546:	00010797          	auipc	a5,0x10
    8000054a:	5a07a523          	sw	zero,1450(a5) # 80010af0 <pr+0x18>
  printf("panic: ");
    8000054e:	00008517          	auipc	a0,0x8
    80000552:	aca50513          	addi	a0,a0,-1334 # 80008018 <etext+0x18>
    80000556:	00000097          	auipc	ra,0x0
    8000055a:	02e080e7          	jalr	46(ra) # 80000584 <printf>
  printf(s);
    8000055e:	8526                	mv	a0,s1
    80000560:	00000097          	auipc	ra,0x0
    80000564:	024080e7          	jalr	36(ra) # 80000584 <printf>
  printf("\n");
    80000568:	00008517          	auipc	a0,0x8
    8000056c:	b8050513          	addi	a0,a0,-1152 # 800080e8 <digits+0xa8>
    80000570:	00000097          	auipc	ra,0x0
    80000574:	014080e7          	jalr	20(ra) # 80000584 <printf>
  panicked = 1; // freeze uart output from other CPUs
    80000578:	4785                	li	a5,1
    8000057a:	00008717          	auipc	a4,0x8
    8000057e:	32f72b23          	sw	a5,822(a4) # 800088b0 <panicked>
  for(;;)
    80000582:	a001                	j	80000582 <panic+0x48>

0000000080000584 <printf>:
{
    80000584:	7131                	addi	sp,sp,-192
    80000586:	fc86                	sd	ra,120(sp)
    80000588:	f8a2                	sd	s0,112(sp)
    8000058a:	f4a6                	sd	s1,104(sp)
    8000058c:	f0ca                	sd	s2,96(sp)
    8000058e:	ecce                	sd	s3,88(sp)
    80000590:	e8d2                	sd	s4,80(sp)
    80000592:	e4d6                	sd	s5,72(sp)
    80000594:	e0da                	sd	s6,64(sp)
    80000596:	fc5e                	sd	s7,56(sp)
    80000598:	f862                	sd	s8,48(sp)
    8000059a:	f466                	sd	s9,40(sp)
    8000059c:	f06a                	sd	s10,32(sp)
    8000059e:	ec6e                	sd	s11,24(sp)
    800005a0:	0100                	addi	s0,sp,128
    800005a2:	8a2a                	mv	s4,a0
    800005a4:	e40c                	sd	a1,8(s0)
    800005a6:	e810                	sd	a2,16(s0)
    800005a8:	ec14                	sd	a3,24(s0)
    800005aa:	f018                	sd	a4,32(s0)
    800005ac:	f41c                	sd	a5,40(s0)
    800005ae:	03043823          	sd	a6,48(s0)
    800005b2:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005b6:	00010d97          	auipc	s11,0x10
    800005ba:	53adad83          	lw	s11,1338(s11) # 80010af0 <pr+0x18>
  if(locking)
    800005be:	020d9b63          	bnez	s11,800005f4 <printf+0x70>
  if (fmt == 0)
    800005c2:	040a0263          	beqz	s4,80000606 <printf+0x82>
  va_start(ap, fmt);
    800005c6:	00840793          	addi	a5,s0,8
    800005ca:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005ce:	000a4503          	lbu	a0,0(s4)
    800005d2:	14050f63          	beqz	a0,80000730 <printf+0x1ac>
    800005d6:	4981                	li	s3,0
    if(c != '%'){
    800005d8:	02500a93          	li	s5,37
    switch(c){
    800005dc:	07000b93          	li	s7,112
  consputc('x');
    800005e0:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e2:	00008b17          	auipc	s6,0x8
    800005e6:	a5eb0b13          	addi	s6,s6,-1442 # 80008040 <digits>
    switch(c){
    800005ea:	07300c93          	li	s9,115
    800005ee:	06400c13          	li	s8,100
    800005f2:	a82d                	j	8000062c <printf+0xa8>
    acquire(&pr.lock);
    800005f4:	00010517          	auipc	a0,0x10
    800005f8:	4e450513          	addi	a0,a0,1252 # 80010ad8 <pr>
    800005fc:	00000097          	auipc	ra,0x0
    80000600:	5d4080e7          	jalr	1492(ra) # 80000bd0 <acquire>
    80000604:	bf7d                	j	800005c2 <printf+0x3e>
    panic("null fmt");
    80000606:	00008517          	auipc	a0,0x8
    8000060a:	a2250513          	addi	a0,a0,-1502 # 80008028 <etext+0x28>
    8000060e:	00000097          	auipc	ra,0x0
    80000612:	f2c080e7          	jalr	-212(ra) # 8000053a <panic>
      consputc(c);
    80000616:	00000097          	auipc	ra,0x0
    8000061a:	c60080e7          	jalr	-928(ra) # 80000276 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    8000061e:	2985                	addiw	s3,s3,1
    80000620:	013a07b3          	add	a5,s4,s3
    80000624:	0007c503          	lbu	a0,0(a5)
    80000628:	10050463          	beqz	a0,80000730 <printf+0x1ac>
    if(c != '%'){
    8000062c:	ff5515e3          	bne	a0,s5,80000616 <printf+0x92>
    c = fmt[++i] & 0xff;
    80000630:	2985                	addiw	s3,s3,1
    80000632:	013a07b3          	add	a5,s4,s3
    80000636:	0007c783          	lbu	a5,0(a5)
    8000063a:	0007849b          	sext.w	s1,a5
    if(c == 0)
    8000063e:	cbed                	beqz	a5,80000730 <printf+0x1ac>
    switch(c){
    80000640:	05778a63          	beq	a5,s7,80000694 <printf+0x110>
    80000644:	02fbf663          	bgeu	s7,a5,80000670 <printf+0xec>
    80000648:	09978863          	beq	a5,s9,800006d8 <printf+0x154>
    8000064c:	07800713          	li	a4,120
    80000650:	0ce79563          	bne	a5,a4,8000071a <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    80000654:	f8843783          	ld	a5,-120(s0)
    80000658:	00878713          	addi	a4,a5,8
    8000065c:	f8e43423          	sd	a4,-120(s0)
    80000660:	4605                	li	a2,1
    80000662:	85ea                	mv	a1,s10
    80000664:	4388                	lw	a0,0(a5)
    80000666:	00000097          	auipc	ra,0x0
    8000066a:	e30080e7          	jalr	-464(ra) # 80000496 <printint>
      break;
    8000066e:	bf45                	j	8000061e <printf+0x9a>
    switch(c){
    80000670:	09578f63          	beq	a5,s5,8000070e <printf+0x18a>
    80000674:	0b879363          	bne	a5,s8,8000071a <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    80000678:	f8843783          	ld	a5,-120(s0)
    8000067c:	00878713          	addi	a4,a5,8
    80000680:	f8e43423          	sd	a4,-120(s0)
    80000684:	4605                	li	a2,1
    80000686:	45a9                	li	a1,10
    80000688:	4388                	lw	a0,0(a5)
    8000068a:	00000097          	auipc	ra,0x0
    8000068e:	e0c080e7          	jalr	-500(ra) # 80000496 <printint>
      break;
    80000692:	b771                	j	8000061e <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000694:	f8843783          	ld	a5,-120(s0)
    80000698:	00878713          	addi	a4,a5,8
    8000069c:	f8e43423          	sd	a4,-120(s0)
    800006a0:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006a4:	03000513          	li	a0,48
    800006a8:	00000097          	auipc	ra,0x0
    800006ac:	bce080e7          	jalr	-1074(ra) # 80000276 <consputc>
  consputc('x');
    800006b0:	07800513          	li	a0,120
    800006b4:	00000097          	auipc	ra,0x0
    800006b8:	bc2080e7          	jalr	-1086(ra) # 80000276 <consputc>
    800006bc:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006be:	03c95793          	srli	a5,s2,0x3c
    800006c2:	97da                	add	a5,a5,s6
    800006c4:	0007c503          	lbu	a0,0(a5)
    800006c8:	00000097          	auipc	ra,0x0
    800006cc:	bae080e7          	jalr	-1106(ra) # 80000276 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d0:	0912                	slli	s2,s2,0x4
    800006d2:	34fd                	addiw	s1,s1,-1
    800006d4:	f4ed                	bnez	s1,800006be <printf+0x13a>
    800006d6:	b7a1                	j	8000061e <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006d8:	f8843783          	ld	a5,-120(s0)
    800006dc:	00878713          	addi	a4,a5,8
    800006e0:	f8e43423          	sd	a4,-120(s0)
    800006e4:	6384                	ld	s1,0(a5)
    800006e6:	cc89                	beqz	s1,80000700 <printf+0x17c>
      for(; *s; s++)
    800006e8:	0004c503          	lbu	a0,0(s1)
    800006ec:	d90d                	beqz	a0,8000061e <printf+0x9a>
        consputc(*s);
    800006ee:	00000097          	auipc	ra,0x0
    800006f2:	b88080e7          	jalr	-1144(ra) # 80000276 <consputc>
      for(; *s; s++)
    800006f6:	0485                	addi	s1,s1,1
    800006f8:	0004c503          	lbu	a0,0(s1)
    800006fc:	f96d                	bnez	a0,800006ee <printf+0x16a>
    800006fe:	b705                	j	8000061e <printf+0x9a>
        s = "(null)";
    80000700:	00008497          	auipc	s1,0x8
    80000704:	92048493          	addi	s1,s1,-1760 # 80008020 <etext+0x20>
      for(; *s; s++)
    80000708:	02800513          	li	a0,40
    8000070c:	b7cd                	j	800006ee <printf+0x16a>
      consputc('%');
    8000070e:	8556                	mv	a0,s5
    80000710:	00000097          	auipc	ra,0x0
    80000714:	b66080e7          	jalr	-1178(ra) # 80000276 <consputc>
      break;
    80000718:	b719                	j	8000061e <printf+0x9a>
      consputc('%');
    8000071a:	8556                	mv	a0,s5
    8000071c:	00000097          	auipc	ra,0x0
    80000720:	b5a080e7          	jalr	-1190(ra) # 80000276 <consputc>
      consputc(c);
    80000724:	8526                	mv	a0,s1
    80000726:	00000097          	auipc	ra,0x0
    8000072a:	b50080e7          	jalr	-1200(ra) # 80000276 <consputc>
      break;
    8000072e:	bdc5                	j	8000061e <printf+0x9a>
  if(locking)
    80000730:	020d9163          	bnez	s11,80000752 <printf+0x1ce>
}
    80000734:	70e6                	ld	ra,120(sp)
    80000736:	7446                	ld	s0,112(sp)
    80000738:	74a6                	ld	s1,104(sp)
    8000073a:	7906                	ld	s2,96(sp)
    8000073c:	69e6                	ld	s3,88(sp)
    8000073e:	6a46                	ld	s4,80(sp)
    80000740:	6aa6                	ld	s5,72(sp)
    80000742:	6b06                	ld	s6,64(sp)
    80000744:	7be2                	ld	s7,56(sp)
    80000746:	7c42                	ld	s8,48(sp)
    80000748:	7ca2                	ld	s9,40(sp)
    8000074a:	7d02                	ld	s10,32(sp)
    8000074c:	6de2                	ld	s11,24(sp)
    8000074e:	6129                	addi	sp,sp,192
    80000750:	8082                	ret
    release(&pr.lock);
    80000752:	00010517          	auipc	a0,0x10
    80000756:	38650513          	addi	a0,a0,902 # 80010ad8 <pr>
    8000075a:	00000097          	auipc	ra,0x0
    8000075e:	52a080e7          	jalr	1322(ra) # 80000c84 <release>
}
    80000762:	bfc9                	j	80000734 <printf+0x1b0>

0000000080000764 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000764:	1101                	addi	sp,sp,-32
    80000766:	ec06                	sd	ra,24(sp)
    80000768:	e822                	sd	s0,16(sp)
    8000076a:	e426                	sd	s1,8(sp)
    8000076c:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    8000076e:	00010497          	auipc	s1,0x10
    80000772:	36a48493          	addi	s1,s1,874 # 80010ad8 <pr>
    80000776:	00008597          	auipc	a1,0x8
    8000077a:	8c258593          	addi	a1,a1,-1854 # 80008038 <etext+0x38>
    8000077e:	8526                	mv	a0,s1
    80000780:	00000097          	auipc	ra,0x0
    80000784:	3c0080e7          	jalr	960(ra) # 80000b40 <initlock>
  pr.locking = 1;
    80000788:	4785                	li	a5,1
    8000078a:	cc9c                	sw	a5,24(s1)
}
    8000078c:	60e2                	ld	ra,24(sp)
    8000078e:	6442                	ld	s0,16(sp)
    80000790:	64a2                	ld	s1,8(sp)
    80000792:	6105                	addi	sp,sp,32
    80000794:	8082                	ret

0000000080000796 <uartinit>:

void uartstart();

void
uartinit(void)
{
    80000796:	1141                	addi	sp,sp,-16
    80000798:	e406                	sd	ra,8(sp)
    8000079a:	e022                	sd	s0,0(sp)
    8000079c:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    8000079e:	100007b7          	lui	a5,0x10000
    800007a2:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007a6:	f8000713          	li	a4,-128
    800007aa:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007ae:	470d                	li	a4,3
    800007b0:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007b4:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007b8:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007bc:	469d                	li	a3,7
    800007be:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007c2:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007c6:	00008597          	auipc	a1,0x8
    800007ca:	89258593          	addi	a1,a1,-1902 # 80008058 <digits+0x18>
    800007ce:	00010517          	auipc	a0,0x10
    800007d2:	32a50513          	addi	a0,a0,810 # 80010af8 <uart_tx_lock>
    800007d6:	00000097          	auipc	ra,0x0
    800007da:	36a080e7          	jalr	874(ra) # 80000b40 <initlock>
}
    800007de:	60a2                	ld	ra,8(sp)
    800007e0:	6402                	ld	s0,0(sp)
    800007e2:	0141                	addi	sp,sp,16
    800007e4:	8082                	ret

00000000800007e6 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007e6:	1101                	addi	sp,sp,-32
    800007e8:	ec06                	sd	ra,24(sp)
    800007ea:	e822                	sd	s0,16(sp)
    800007ec:	e426                	sd	s1,8(sp)
    800007ee:	1000                	addi	s0,sp,32
    800007f0:	84aa                	mv	s1,a0
  push_off();
    800007f2:	00000097          	auipc	ra,0x0
    800007f6:	392080e7          	jalr	914(ra) # 80000b84 <push_off>

  if(panicked){
    800007fa:	00008797          	auipc	a5,0x8
    800007fe:	0b67a783          	lw	a5,182(a5) # 800088b0 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000802:	10000737          	lui	a4,0x10000
  if(panicked){
    80000806:	c391                	beqz	a5,8000080a <uartputc_sync+0x24>
    for(;;)
    80000808:	a001                	j	80000808 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000080a:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    8000080e:	0207f793          	andi	a5,a5,32
    80000812:	dfe5                	beqz	a5,8000080a <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000814:	0ff4f513          	zext.b	a0,s1
    80000818:	100007b7          	lui	a5,0x10000
    8000081c:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000820:	00000097          	auipc	ra,0x0
    80000824:	404080e7          	jalr	1028(ra) # 80000c24 <pop_off>
}
    80000828:	60e2                	ld	ra,24(sp)
    8000082a:	6442                	ld	s0,16(sp)
    8000082c:	64a2                	ld	s1,8(sp)
    8000082e:	6105                	addi	sp,sp,32
    80000830:	8082                	ret

0000000080000832 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000832:	00008797          	auipc	a5,0x8
    80000836:	0867b783          	ld	a5,134(a5) # 800088b8 <uart_tx_r>
    8000083a:	00008717          	auipc	a4,0x8
    8000083e:	08673703          	ld	a4,134(a4) # 800088c0 <uart_tx_w>
    80000842:	06f70a63          	beq	a4,a5,800008b6 <uartstart+0x84>
{
    80000846:	7139                	addi	sp,sp,-64
    80000848:	fc06                	sd	ra,56(sp)
    8000084a:	f822                	sd	s0,48(sp)
    8000084c:	f426                	sd	s1,40(sp)
    8000084e:	f04a                	sd	s2,32(sp)
    80000850:	ec4e                	sd	s3,24(sp)
    80000852:	e852                	sd	s4,16(sp)
    80000854:	e456                	sd	s5,8(sp)
    80000856:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000858:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000085c:	00010a17          	auipc	s4,0x10
    80000860:	29ca0a13          	addi	s4,s4,668 # 80010af8 <uart_tx_lock>
    uart_tx_r += 1;
    80000864:	00008497          	auipc	s1,0x8
    80000868:	05448493          	addi	s1,s1,84 # 800088b8 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000086c:	00008997          	auipc	s3,0x8
    80000870:	05498993          	addi	s3,s3,84 # 800088c0 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000874:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000878:	02077713          	andi	a4,a4,32
    8000087c:	c705                	beqz	a4,800008a4 <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000087e:	01f7f713          	andi	a4,a5,31
    80000882:	9752                	add	a4,a4,s4
    80000884:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    80000888:	0785                	addi	a5,a5,1
    8000088a:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    8000088c:	8526                	mv	a0,s1
    8000088e:	00002097          	auipc	ra,0x2
    80000892:	812080e7          	jalr	-2030(ra) # 800020a0 <wakeup>
    
    WriteReg(THR, c);
    80000896:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    8000089a:	609c                	ld	a5,0(s1)
    8000089c:	0009b703          	ld	a4,0(s3)
    800008a0:	fcf71ae3          	bne	a4,a5,80000874 <uartstart+0x42>
  }
}
    800008a4:	70e2                	ld	ra,56(sp)
    800008a6:	7442                	ld	s0,48(sp)
    800008a8:	74a2                	ld	s1,40(sp)
    800008aa:	7902                	ld	s2,32(sp)
    800008ac:	69e2                	ld	s3,24(sp)
    800008ae:	6a42                	ld	s4,16(sp)
    800008b0:	6aa2                	ld	s5,8(sp)
    800008b2:	6121                	addi	sp,sp,64
    800008b4:	8082                	ret
    800008b6:	8082                	ret

00000000800008b8 <uartputc>:
{
    800008b8:	7179                	addi	sp,sp,-48
    800008ba:	f406                	sd	ra,40(sp)
    800008bc:	f022                	sd	s0,32(sp)
    800008be:	ec26                	sd	s1,24(sp)
    800008c0:	e84a                	sd	s2,16(sp)
    800008c2:	e44e                	sd	s3,8(sp)
    800008c4:	e052                	sd	s4,0(sp)
    800008c6:	1800                	addi	s0,sp,48
    800008c8:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800008ca:	00010517          	auipc	a0,0x10
    800008ce:	22e50513          	addi	a0,a0,558 # 80010af8 <uart_tx_lock>
    800008d2:	00000097          	auipc	ra,0x0
    800008d6:	2fe080e7          	jalr	766(ra) # 80000bd0 <acquire>
  if(panicked){
    800008da:	00008797          	auipc	a5,0x8
    800008de:	fd67a783          	lw	a5,-42(a5) # 800088b0 <panicked>
    800008e2:	e7c9                	bnez	a5,8000096c <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008e4:	00008717          	auipc	a4,0x8
    800008e8:	fdc73703          	ld	a4,-36(a4) # 800088c0 <uart_tx_w>
    800008ec:	00008797          	auipc	a5,0x8
    800008f0:	fcc7b783          	ld	a5,-52(a5) # 800088b8 <uart_tx_r>
    800008f4:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    800008f8:	00010997          	auipc	s3,0x10
    800008fc:	20098993          	addi	s3,s3,512 # 80010af8 <uart_tx_lock>
    80000900:	00008497          	auipc	s1,0x8
    80000904:	fb848493          	addi	s1,s1,-72 # 800088b8 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000908:	00008917          	auipc	s2,0x8
    8000090c:	fb890913          	addi	s2,s2,-72 # 800088c0 <uart_tx_w>
    80000910:	00e79f63          	bne	a5,a4,8000092e <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    80000914:	85ce                	mv	a1,s3
    80000916:	8526                	mv	a0,s1
    80000918:	00001097          	auipc	ra,0x1
    8000091c:	724080e7          	jalr	1828(ra) # 8000203c <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000920:	00093703          	ld	a4,0(s2)
    80000924:	609c                	ld	a5,0(s1)
    80000926:	02078793          	addi	a5,a5,32
    8000092a:	fee785e3          	beq	a5,a4,80000914 <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    8000092e:	00010497          	auipc	s1,0x10
    80000932:	1ca48493          	addi	s1,s1,458 # 80010af8 <uart_tx_lock>
    80000936:	01f77793          	andi	a5,a4,31
    8000093a:	97a6                	add	a5,a5,s1
    8000093c:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000940:	0705                	addi	a4,a4,1
    80000942:	00008797          	auipc	a5,0x8
    80000946:	f6e7bf23          	sd	a4,-130(a5) # 800088c0 <uart_tx_w>
  uartstart();
    8000094a:	00000097          	auipc	ra,0x0
    8000094e:	ee8080e7          	jalr	-280(ra) # 80000832 <uartstart>
  release(&uart_tx_lock);
    80000952:	8526                	mv	a0,s1
    80000954:	00000097          	auipc	ra,0x0
    80000958:	330080e7          	jalr	816(ra) # 80000c84 <release>
}
    8000095c:	70a2                	ld	ra,40(sp)
    8000095e:	7402                	ld	s0,32(sp)
    80000960:	64e2                	ld	s1,24(sp)
    80000962:	6942                	ld	s2,16(sp)
    80000964:	69a2                	ld	s3,8(sp)
    80000966:	6a02                	ld	s4,0(sp)
    80000968:	6145                	addi	sp,sp,48
    8000096a:	8082                	ret
    for(;;)
    8000096c:	a001                	j	8000096c <uartputc+0xb4>

000000008000096e <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    8000096e:	1141                	addi	sp,sp,-16
    80000970:	e422                	sd	s0,8(sp)
    80000972:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000974:	100007b7          	lui	a5,0x10000
    80000978:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    8000097c:	8b85                	andi	a5,a5,1
    8000097e:	cb81                	beqz	a5,8000098e <uartgetc+0x20>
    // input data is ready.
    return ReadReg(RHR);
    80000980:	100007b7          	lui	a5,0x10000
    80000984:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
  } else {
    return -1;
  }
}
    80000988:	6422                	ld	s0,8(sp)
    8000098a:	0141                	addi	sp,sp,16
    8000098c:	8082                	ret
    return -1;
    8000098e:	557d                	li	a0,-1
    80000990:	bfe5                	j	80000988 <uartgetc+0x1a>

0000000080000992 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    80000992:	1101                	addi	sp,sp,-32
    80000994:	ec06                	sd	ra,24(sp)
    80000996:	e822                	sd	s0,16(sp)
    80000998:	e426                	sd	s1,8(sp)
    8000099a:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    8000099c:	54fd                	li	s1,-1
    8000099e:	a029                	j	800009a8 <uartintr+0x16>
      break;
    consoleintr(c);
    800009a0:	00000097          	auipc	ra,0x0
    800009a4:	918080e7          	jalr	-1768(ra) # 800002b8 <consoleintr>
    int c = uartgetc();
    800009a8:	00000097          	auipc	ra,0x0
    800009ac:	fc6080e7          	jalr	-58(ra) # 8000096e <uartgetc>
    if(c == -1)
    800009b0:	fe9518e3          	bne	a0,s1,800009a0 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009b4:	00010497          	auipc	s1,0x10
    800009b8:	14448493          	addi	s1,s1,324 # 80010af8 <uart_tx_lock>
    800009bc:	8526                	mv	a0,s1
    800009be:	00000097          	auipc	ra,0x0
    800009c2:	212080e7          	jalr	530(ra) # 80000bd0 <acquire>
  uartstart();
    800009c6:	00000097          	auipc	ra,0x0
    800009ca:	e6c080e7          	jalr	-404(ra) # 80000832 <uartstart>
  release(&uart_tx_lock);
    800009ce:	8526                	mv	a0,s1
    800009d0:	00000097          	auipc	ra,0x0
    800009d4:	2b4080e7          	jalr	692(ra) # 80000c84 <release>
}
    800009d8:	60e2                	ld	ra,24(sp)
    800009da:	6442                	ld	s0,16(sp)
    800009dc:	64a2                	ld	s1,8(sp)
    800009de:	6105                	addi	sp,sp,32
    800009e0:	8082                	ret

00000000800009e2 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009e2:	1101                	addi	sp,sp,-32
    800009e4:	ec06                	sd	ra,24(sp)
    800009e6:	e822                	sd	s0,16(sp)
    800009e8:	e426                	sd	s1,8(sp)
    800009ea:	e04a                	sd	s2,0(sp)
    800009ec:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    800009ee:	03451793          	slli	a5,a0,0x34
    800009f2:	ebb9                	bnez	a5,80000a48 <kfree+0x66>
    800009f4:	84aa                	mv	s1,a0
    800009f6:	00021797          	auipc	a5,0x21
    800009fa:	36a78793          	addi	a5,a5,874 # 80021d60 <end>
    800009fe:	04f56563          	bltu	a0,a5,80000a48 <kfree+0x66>
    80000a02:	47c5                	li	a5,17
    80000a04:	07ee                	slli	a5,a5,0x1b
    80000a06:	04f57163          	bgeu	a0,a5,80000a48 <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a0a:	6605                	lui	a2,0x1
    80000a0c:	4585                	li	a1,1
    80000a0e:	00000097          	auipc	ra,0x0
    80000a12:	2be080e7          	jalr	702(ra) # 80000ccc <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a16:	00010917          	auipc	s2,0x10
    80000a1a:	11a90913          	addi	s2,s2,282 # 80010b30 <kmem>
    80000a1e:	854a                	mv	a0,s2
    80000a20:	00000097          	auipc	ra,0x0
    80000a24:	1b0080e7          	jalr	432(ra) # 80000bd0 <acquire>
  r->next = kmem.freelist;
    80000a28:	01893783          	ld	a5,24(s2)
    80000a2c:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a2e:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a32:	854a                	mv	a0,s2
    80000a34:	00000097          	auipc	ra,0x0
    80000a38:	250080e7          	jalr	592(ra) # 80000c84 <release>
}
    80000a3c:	60e2                	ld	ra,24(sp)
    80000a3e:	6442                	ld	s0,16(sp)
    80000a40:	64a2                	ld	s1,8(sp)
    80000a42:	6902                	ld	s2,0(sp)
    80000a44:	6105                	addi	sp,sp,32
    80000a46:	8082                	ret
    panic("kfree");
    80000a48:	00007517          	auipc	a0,0x7
    80000a4c:	61850513          	addi	a0,a0,1560 # 80008060 <digits+0x20>
    80000a50:	00000097          	auipc	ra,0x0
    80000a54:	aea080e7          	jalr	-1302(ra) # 8000053a <panic>

0000000080000a58 <freerange>:
{
    80000a58:	7179                	addi	sp,sp,-48
    80000a5a:	f406                	sd	ra,40(sp)
    80000a5c:	f022                	sd	s0,32(sp)
    80000a5e:	ec26                	sd	s1,24(sp)
    80000a60:	e84a                	sd	s2,16(sp)
    80000a62:	e44e                	sd	s3,8(sp)
    80000a64:	e052                	sd	s4,0(sp)
    80000a66:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a68:	6785                	lui	a5,0x1
    80000a6a:	fff78713          	addi	a4,a5,-1 # fff <_entry-0x7ffff001>
    80000a6e:	00e504b3          	add	s1,a0,a4
    80000a72:	777d                	lui	a4,0xfffff
    80000a74:	8cf9                	and	s1,s1,a4
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a76:	94be                	add	s1,s1,a5
    80000a78:	0095ee63          	bltu	a1,s1,80000a94 <freerange+0x3c>
    80000a7c:	892e                	mv	s2,a1
    kfree(p);
    80000a7e:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a80:	6985                	lui	s3,0x1
    kfree(p);
    80000a82:	01448533          	add	a0,s1,s4
    80000a86:	00000097          	auipc	ra,0x0
    80000a8a:	f5c080e7          	jalr	-164(ra) # 800009e2 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a8e:	94ce                	add	s1,s1,s3
    80000a90:	fe9979e3          	bgeu	s2,s1,80000a82 <freerange+0x2a>
}
    80000a94:	70a2                	ld	ra,40(sp)
    80000a96:	7402                	ld	s0,32(sp)
    80000a98:	64e2                	ld	s1,24(sp)
    80000a9a:	6942                	ld	s2,16(sp)
    80000a9c:	69a2                	ld	s3,8(sp)
    80000a9e:	6a02                	ld	s4,0(sp)
    80000aa0:	6145                	addi	sp,sp,48
    80000aa2:	8082                	ret

0000000080000aa4 <kinit>:
{
    80000aa4:	1141                	addi	sp,sp,-16
    80000aa6:	e406                	sd	ra,8(sp)
    80000aa8:	e022                	sd	s0,0(sp)
    80000aaa:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000aac:	00007597          	auipc	a1,0x7
    80000ab0:	5bc58593          	addi	a1,a1,1468 # 80008068 <digits+0x28>
    80000ab4:	00010517          	auipc	a0,0x10
    80000ab8:	07c50513          	addi	a0,a0,124 # 80010b30 <kmem>
    80000abc:	00000097          	auipc	ra,0x0
    80000ac0:	084080e7          	jalr	132(ra) # 80000b40 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ac4:	45c5                	li	a1,17
    80000ac6:	05ee                	slli	a1,a1,0x1b
    80000ac8:	00021517          	auipc	a0,0x21
    80000acc:	29850513          	addi	a0,a0,664 # 80021d60 <end>
    80000ad0:	00000097          	auipc	ra,0x0
    80000ad4:	f88080e7          	jalr	-120(ra) # 80000a58 <freerange>
}
    80000ad8:	60a2                	ld	ra,8(sp)
    80000ada:	6402                	ld	s0,0(sp)
    80000adc:	0141                	addi	sp,sp,16
    80000ade:	8082                	ret

0000000080000ae0 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000ae0:	1101                	addi	sp,sp,-32
    80000ae2:	ec06                	sd	ra,24(sp)
    80000ae4:	e822                	sd	s0,16(sp)
    80000ae6:	e426                	sd	s1,8(sp)
    80000ae8:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000aea:	00010497          	auipc	s1,0x10
    80000aee:	04648493          	addi	s1,s1,70 # 80010b30 <kmem>
    80000af2:	8526                	mv	a0,s1
    80000af4:	00000097          	auipc	ra,0x0
    80000af8:	0dc080e7          	jalr	220(ra) # 80000bd0 <acquire>
  r = kmem.freelist;
    80000afc:	6c84                	ld	s1,24(s1)
  if(r)
    80000afe:	c885                	beqz	s1,80000b2e <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b00:	609c                	ld	a5,0(s1)
    80000b02:	00010517          	auipc	a0,0x10
    80000b06:	02e50513          	addi	a0,a0,46 # 80010b30 <kmem>
    80000b0a:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b0c:	00000097          	auipc	ra,0x0
    80000b10:	178080e7          	jalr	376(ra) # 80000c84 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b14:	6605                	lui	a2,0x1
    80000b16:	4595                	li	a1,5
    80000b18:	8526                	mv	a0,s1
    80000b1a:	00000097          	auipc	ra,0x0
    80000b1e:	1b2080e7          	jalr	434(ra) # 80000ccc <memset>
  return (void*)r;
}
    80000b22:	8526                	mv	a0,s1
    80000b24:	60e2                	ld	ra,24(sp)
    80000b26:	6442                	ld	s0,16(sp)
    80000b28:	64a2                	ld	s1,8(sp)
    80000b2a:	6105                	addi	sp,sp,32
    80000b2c:	8082                	ret
  release(&kmem.lock);
    80000b2e:	00010517          	auipc	a0,0x10
    80000b32:	00250513          	addi	a0,a0,2 # 80010b30 <kmem>
    80000b36:	00000097          	auipc	ra,0x0
    80000b3a:	14e080e7          	jalr	334(ra) # 80000c84 <release>
  if(r)
    80000b3e:	b7d5                	j	80000b22 <kalloc+0x42>

0000000080000b40 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b40:	1141                	addi	sp,sp,-16
    80000b42:	e422                	sd	s0,8(sp)
    80000b44:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b46:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b48:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b4c:	00053823          	sd	zero,16(a0)
}
    80000b50:	6422                	ld	s0,8(sp)
    80000b52:	0141                	addi	sp,sp,16
    80000b54:	8082                	ret

0000000080000b56 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b56:	411c                	lw	a5,0(a0)
    80000b58:	e399                	bnez	a5,80000b5e <holding+0x8>
    80000b5a:	4501                	li	a0,0
  return r;
}
    80000b5c:	8082                	ret
{
    80000b5e:	1101                	addi	sp,sp,-32
    80000b60:	ec06                	sd	ra,24(sp)
    80000b62:	e822                	sd	s0,16(sp)
    80000b64:	e426                	sd	s1,8(sp)
    80000b66:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b68:	6904                	ld	s1,16(a0)
    80000b6a:	00001097          	auipc	ra,0x1
    80000b6e:	e0e080e7          	jalr	-498(ra) # 80001978 <mycpu>
    80000b72:	40a48533          	sub	a0,s1,a0
    80000b76:	00153513          	seqz	a0,a0
}
    80000b7a:	60e2                	ld	ra,24(sp)
    80000b7c:	6442                	ld	s0,16(sp)
    80000b7e:	64a2                	ld	s1,8(sp)
    80000b80:	6105                	addi	sp,sp,32
    80000b82:	8082                	ret

0000000080000b84 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b84:	1101                	addi	sp,sp,-32
    80000b86:	ec06                	sd	ra,24(sp)
    80000b88:	e822                	sd	s0,16(sp)
    80000b8a:	e426                	sd	s1,8(sp)
    80000b8c:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000b8e:	100024f3          	csrr	s1,sstatus
    80000b92:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000b96:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000b98:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000b9c:	00001097          	auipc	ra,0x1
    80000ba0:	ddc080e7          	jalr	-548(ra) # 80001978 <mycpu>
    80000ba4:	5d3c                	lw	a5,120(a0)
    80000ba6:	cf89                	beqz	a5,80000bc0 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000ba8:	00001097          	auipc	ra,0x1
    80000bac:	dd0080e7          	jalr	-560(ra) # 80001978 <mycpu>
    80000bb0:	5d3c                	lw	a5,120(a0)
    80000bb2:	2785                	addiw	a5,a5,1
    80000bb4:	dd3c                	sw	a5,120(a0)
}
    80000bb6:	60e2                	ld	ra,24(sp)
    80000bb8:	6442                	ld	s0,16(sp)
    80000bba:	64a2                	ld	s1,8(sp)
    80000bbc:	6105                	addi	sp,sp,32
    80000bbe:	8082                	ret
    mycpu()->intena = old;
    80000bc0:	00001097          	auipc	ra,0x1
    80000bc4:	db8080e7          	jalr	-584(ra) # 80001978 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bc8:	8085                	srli	s1,s1,0x1
    80000bca:	8885                	andi	s1,s1,1
    80000bcc:	dd64                	sw	s1,124(a0)
    80000bce:	bfe9                	j	80000ba8 <push_off+0x24>

0000000080000bd0 <acquire>:
{
    80000bd0:	1101                	addi	sp,sp,-32
    80000bd2:	ec06                	sd	ra,24(sp)
    80000bd4:	e822                	sd	s0,16(sp)
    80000bd6:	e426                	sd	s1,8(sp)
    80000bd8:	1000                	addi	s0,sp,32
    80000bda:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000bdc:	00000097          	auipc	ra,0x0
    80000be0:	fa8080e7          	jalr	-88(ra) # 80000b84 <push_off>
  if(holding(lk))
    80000be4:	8526                	mv	a0,s1
    80000be6:	00000097          	auipc	ra,0x0
    80000bea:	f70080e7          	jalr	-144(ra) # 80000b56 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bee:	4705                	li	a4,1
  if(holding(lk))
    80000bf0:	e115                	bnez	a0,80000c14 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf2:	87ba                	mv	a5,a4
    80000bf4:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000bf8:	2781                	sext.w	a5,a5
    80000bfa:	ffe5                	bnez	a5,80000bf2 <acquire+0x22>
  __sync_synchronize();
    80000bfc:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c00:	00001097          	auipc	ra,0x1
    80000c04:	d78080e7          	jalr	-648(ra) # 80001978 <mycpu>
    80000c08:	e888                	sd	a0,16(s1)
}
    80000c0a:	60e2                	ld	ra,24(sp)
    80000c0c:	6442                	ld	s0,16(sp)
    80000c0e:	64a2                	ld	s1,8(sp)
    80000c10:	6105                	addi	sp,sp,32
    80000c12:	8082                	ret
    panic("acquire");
    80000c14:	00007517          	auipc	a0,0x7
    80000c18:	45c50513          	addi	a0,a0,1116 # 80008070 <digits+0x30>
    80000c1c:	00000097          	auipc	ra,0x0
    80000c20:	91e080e7          	jalr	-1762(ra) # 8000053a <panic>

0000000080000c24 <pop_off>:

void
pop_off(void)
{
    80000c24:	1141                	addi	sp,sp,-16
    80000c26:	e406                	sd	ra,8(sp)
    80000c28:	e022                	sd	s0,0(sp)
    80000c2a:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c2c:	00001097          	auipc	ra,0x1
    80000c30:	d4c080e7          	jalr	-692(ra) # 80001978 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c34:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c38:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c3a:	e78d                	bnez	a5,80000c64 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c3c:	5d3c                	lw	a5,120(a0)
    80000c3e:	02f05b63          	blez	a5,80000c74 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c42:	37fd                	addiw	a5,a5,-1
    80000c44:	0007871b          	sext.w	a4,a5
    80000c48:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c4a:	eb09                	bnez	a4,80000c5c <pop_off+0x38>
    80000c4c:	5d7c                	lw	a5,124(a0)
    80000c4e:	c799                	beqz	a5,80000c5c <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c50:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c54:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c58:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c5c:	60a2                	ld	ra,8(sp)
    80000c5e:	6402                	ld	s0,0(sp)
    80000c60:	0141                	addi	sp,sp,16
    80000c62:	8082                	ret
    panic("pop_off - interruptible");
    80000c64:	00007517          	auipc	a0,0x7
    80000c68:	41450513          	addi	a0,a0,1044 # 80008078 <digits+0x38>
    80000c6c:	00000097          	auipc	ra,0x0
    80000c70:	8ce080e7          	jalr	-1842(ra) # 8000053a <panic>
    panic("pop_off");
    80000c74:	00007517          	auipc	a0,0x7
    80000c78:	41c50513          	addi	a0,a0,1052 # 80008090 <digits+0x50>
    80000c7c:	00000097          	auipc	ra,0x0
    80000c80:	8be080e7          	jalr	-1858(ra) # 8000053a <panic>

0000000080000c84 <release>:
{
    80000c84:	1101                	addi	sp,sp,-32
    80000c86:	ec06                	sd	ra,24(sp)
    80000c88:	e822                	sd	s0,16(sp)
    80000c8a:	e426                	sd	s1,8(sp)
    80000c8c:	1000                	addi	s0,sp,32
    80000c8e:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000c90:	00000097          	auipc	ra,0x0
    80000c94:	ec6080e7          	jalr	-314(ra) # 80000b56 <holding>
    80000c98:	c115                	beqz	a0,80000cbc <release+0x38>
  lk->cpu = 0;
    80000c9a:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000c9e:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000ca2:	0f50000f          	fence	iorw,ow
    80000ca6:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000caa:	00000097          	auipc	ra,0x0
    80000cae:	f7a080e7          	jalr	-134(ra) # 80000c24 <pop_off>
}
    80000cb2:	60e2                	ld	ra,24(sp)
    80000cb4:	6442                	ld	s0,16(sp)
    80000cb6:	64a2                	ld	s1,8(sp)
    80000cb8:	6105                	addi	sp,sp,32
    80000cba:	8082                	ret
    panic("release");
    80000cbc:	00007517          	auipc	a0,0x7
    80000cc0:	3dc50513          	addi	a0,a0,988 # 80008098 <digits+0x58>
    80000cc4:	00000097          	auipc	ra,0x0
    80000cc8:	876080e7          	jalr	-1930(ra) # 8000053a <panic>

0000000080000ccc <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000ccc:	1141                	addi	sp,sp,-16
    80000cce:	e422                	sd	s0,8(sp)
    80000cd0:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cd2:	ca19                	beqz	a2,80000ce8 <memset+0x1c>
    80000cd4:	87aa                	mv	a5,a0
    80000cd6:	1602                	slli	a2,a2,0x20
    80000cd8:	9201                	srli	a2,a2,0x20
    80000cda:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000cde:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000ce2:	0785                	addi	a5,a5,1
    80000ce4:	fee79de3          	bne	a5,a4,80000cde <memset+0x12>
  }
  return dst;
}
    80000ce8:	6422                	ld	s0,8(sp)
    80000cea:	0141                	addi	sp,sp,16
    80000cec:	8082                	ret

0000000080000cee <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000cee:	1141                	addi	sp,sp,-16
    80000cf0:	e422                	sd	s0,8(sp)
    80000cf2:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000cf4:	ca05                	beqz	a2,80000d24 <memcmp+0x36>
    80000cf6:	fff6069b          	addiw	a3,a2,-1 # fff <_entry-0x7ffff001>
    80000cfa:	1682                	slli	a3,a3,0x20
    80000cfc:	9281                	srli	a3,a3,0x20
    80000cfe:	0685                	addi	a3,a3,1
    80000d00:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d02:	00054783          	lbu	a5,0(a0)
    80000d06:	0005c703          	lbu	a4,0(a1)
    80000d0a:	00e79863          	bne	a5,a4,80000d1a <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d0e:	0505                	addi	a0,a0,1
    80000d10:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d12:	fed518e3          	bne	a0,a3,80000d02 <memcmp+0x14>
  }

  return 0;
    80000d16:	4501                	li	a0,0
    80000d18:	a019                	j	80000d1e <memcmp+0x30>
      return *s1 - *s2;
    80000d1a:	40e7853b          	subw	a0,a5,a4
}
    80000d1e:	6422                	ld	s0,8(sp)
    80000d20:	0141                	addi	sp,sp,16
    80000d22:	8082                	ret
  return 0;
    80000d24:	4501                	li	a0,0
    80000d26:	bfe5                	j	80000d1e <memcmp+0x30>

0000000080000d28 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d28:	1141                	addi	sp,sp,-16
    80000d2a:	e422                	sd	s0,8(sp)
    80000d2c:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d2e:	c205                	beqz	a2,80000d4e <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d30:	02a5e263          	bltu	a1,a0,80000d54 <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d34:	1602                	slli	a2,a2,0x20
    80000d36:	9201                	srli	a2,a2,0x20
    80000d38:	00c587b3          	add	a5,a1,a2
{
    80000d3c:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d3e:	0585                	addi	a1,a1,1
    80000d40:	0705                	addi	a4,a4,1 # fffffffffffff001 <end+0xffffffff7ffdd2a1>
    80000d42:	fff5c683          	lbu	a3,-1(a1)
    80000d46:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d4a:	fef59ae3          	bne	a1,a5,80000d3e <memmove+0x16>

  return dst;
}
    80000d4e:	6422                	ld	s0,8(sp)
    80000d50:	0141                	addi	sp,sp,16
    80000d52:	8082                	ret
  if(s < d && s + n > d){
    80000d54:	02061693          	slli	a3,a2,0x20
    80000d58:	9281                	srli	a3,a3,0x20
    80000d5a:	00d58733          	add	a4,a1,a3
    80000d5e:	fce57be3          	bgeu	a0,a4,80000d34 <memmove+0xc>
    d += n;
    80000d62:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d64:	fff6079b          	addiw	a5,a2,-1
    80000d68:	1782                	slli	a5,a5,0x20
    80000d6a:	9381                	srli	a5,a5,0x20
    80000d6c:	fff7c793          	not	a5,a5
    80000d70:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d72:	177d                	addi	a4,a4,-1
    80000d74:	16fd                	addi	a3,a3,-1
    80000d76:	00074603          	lbu	a2,0(a4)
    80000d7a:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d7e:	fee79ae3          	bne	a5,a4,80000d72 <memmove+0x4a>
    80000d82:	b7f1                	j	80000d4e <memmove+0x26>

0000000080000d84 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000d84:	1141                	addi	sp,sp,-16
    80000d86:	e406                	sd	ra,8(sp)
    80000d88:	e022                	sd	s0,0(sp)
    80000d8a:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000d8c:	00000097          	auipc	ra,0x0
    80000d90:	f9c080e7          	jalr	-100(ra) # 80000d28 <memmove>
}
    80000d94:	60a2                	ld	ra,8(sp)
    80000d96:	6402                	ld	s0,0(sp)
    80000d98:	0141                	addi	sp,sp,16
    80000d9a:	8082                	ret

0000000080000d9c <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000d9c:	1141                	addi	sp,sp,-16
    80000d9e:	e422                	sd	s0,8(sp)
    80000da0:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000da2:	ce11                	beqz	a2,80000dbe <strncmp+0x22>
    80000da4:	00054783          	lbu	a5,0(a0)
    80000da8:	cf89                	beqz	a5,80000dc2 <strncmp+0x26>
    80000daa:	0005c703          	lbu	a4,0(a1)
    80000dae:	00f71a63          	bne	a4,a5,80000dc2 <strncmp+0x26>
    n--, p++, q++;
    80000db2:	367d                	addiw	a2,a2,-1
    80000db4:	0505                	addi	a0,a0,1
    80000db6:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000db8:	f675                	bnez	a2,80000da4 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dba:	4501                	li	a0,0
    80000dbc:	a809                	j	80000dce <strncmp+0x32>
    80000dbe:	4501                	li	a0,0
    80000dc0:	a039                	j	80000dce <strncmp+0x32>
  if(n == 0)
    80000dc2:	ca09                	beqz	a2,80000dd4 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000dc4:	00054503          	lbu	a0,0(a0)
    80000dc8:	0005c783          	lbu	a5,0(a1)
    80000dcc:	9d1d                	subw	a0,a0,a5
}
    80000dce:	6422                	ld	s0,8(sp)
    80000dd0:	0141                	addi	sp,sp,16
    80000dd2:	8082                	ret
    return 0;
    80000dd4:	4501                	li	a0,0
    80000dd6:	bfe5                	j	80000dce <strncmp+0x32>

0000000080000dd8 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000dd8:	1141                	addi	sp,sp,-16
    80000dda:	e422                	sd	s0,8(sp)
    80000ddc:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000dde:	87aa                	mv	a5,a0
    80000de0:	86b2                	mv	a3,a2
    80000de2:	367d                	addiw	a2,a2,-1
    80000de4:	00d05963          	blez	a3,80000df6 <strncpy+0x1e>
    80000de8:	0785                	addi	a5,a5,1
    80000dea:	0005c703          	lbu	a4,0(a1)
    80000dee:	fee78fa3          	sb	a4,-1(a5)
    80000df2:	0585                	addi	a1,a1,1
    80000df4:	f775                	bnez	a4,80000de0 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000df6:	873e                	mv	a4,a5
    80000df8:	9fb5                	addw	a5,a5,a3
    80000dfa:	37fd                	addiw	a5,a5,-1
    80000dfc:	00c05963          	blez	a2,80000e0e <strncpy+0x36>
    *s++ = 0;
    80000e00:	0705                	addi	a4,a4,1
    80000e02:	fe070fa3          	sb	zero,-1(a4)
  while(n-- > 0)
    80000e06:	40e786bb          	subw	a3,a5,a4
    80000e0a:	fed04be3          	bgtz	a3,80000e00 <strncpy+0x28>
  return os;
}
    80000e0e:	6422                	ld	s0,8(sp)
    80000e10:	0141                	addi	sp,sp,16
    80000e12:	8082                	ret

0000000080000e14 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e14:	1141                	addi	sp,sp,-16
    80000e16:	e422                	sd	s0,8(sp)
    80000e18:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e1a:	02c05363          	blez	a2,80000e40 <safestrcpy+0x2c>
    80000e1e:	fff6069b          	addiw	a3,a2,-1
    80000e22:	1682                	slli	a3,a3,0x20
    80000e24:	9281                	srli	a3,a3,0x20
    80000e26:	96ae                	add	a3,a3,a1
    80000e28:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e2a:	00d58963          	beq	a1,a3,80000e3c <safestrcpy+0x28>
    80000e2e:	0585                	addi	a1,a1,1
    80000e30:	0785                	addi	a5,a5,1
    80000e32:	fff5c703          	lbu	a4,-1(a1)
    80000e36:	fee78fa3          	sb	a4,-1(a5)
    80000e3a:	fb65                	bnez	a4,80000e2a <safestrcpy+0x16>
    ;
  *s = 0;
    80000e3c:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e40:	6422                	ld	s0,8(sp)
    80000e42:	0141                	addi	sp,sp,16
    80000e44:	8082                	ret

0000000080000e46 <strlen>:

int
strlen(const char *s)
{
    80000e46:	1141                	addi	sp,sp,-16
    80000e48:	e422                	sd	s0,8(sp)
    80000e4a:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e4c:	00054783          	lbu	a5,0(a0)
    80000e50:	cf91                	beqz	a5,80000e6c <strlen+0x26>
    80000e52:	0505                	addi	a0,a0,1
    80000e54:	87aa                	mv	a5,a0
    80000e56:	86be                	mv	a3,a5
    80000e58:	0785                	addi	a5,a5,1
    80000e5a:	fff7c703          	lbu	a4,-1(a5)
    80000e5e:	ff65                	bnez	a4,80000e56 <strlen+0x10>
    80000e60:	40a6853b          	subw	a0,a3,a0
    80000e64:	2505                	addiw	a0,a0,1
    ;
  return n;
}
    80000e66:	6422                	ld	s0,8(sp)
    80000e68:	0141                	addi	sp,sp,16
    80000e6a:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e6c:	4501                	li	a0,0
    80000e6e:	bfe5                	j	80000e66 <strlen+0x20>

0000000080000e70 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e70:	1141                	addi	sp,sp,-16
    80000e72:	e406                	sd	ra,8(sp)
    80000e74:	e022                	sd	s0,0(sp)
    80000e76:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e78:	00001097          	auipc	ra,0x1
    80000e7c:	af0080e7          	jalr	-1296(ra) # 80001968 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e80:	00008717          	auipc	a4,0x8
    80000e84:	a4870713          	addi	a4,a4,-1464 # 800088c8 <started>
  if(cpuid() == 0){
    80000e88:	c139                	beqz	a0,80000ece <main+0x5e>
    while(started == 0)
    80000e8a:	431c                	lw	a5,0(a4)
    80000e8c:	2781                	sext.w	a5,a5
    80000e8e:	dff5                	beqz	a5,80000e8a <main+0x1a>
      ;
    __sync_synchronize();
    80000e90:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000e94:	00001097          	auipc	ra,0x1
    80000e98:	ad4080e7          	jalr	-1324(ra) # 80001968 <cpuid>
    80000e9c:	85aa                	mv	a1,a0
    80000e9e:	00007517          	auipc	a0,0x7
    80000ea2:	23a50513          	addi	a0,a0,570 # 800080d8 <digits+0x98>
    80000ea6:	fffff097          	auipc	ra,0xfffff
    80000eaa:	6de080e7          	jalr	1758(ra) # 80000584 <printf>
    kvminithart();    // turn on paging
    80000eae:	00000097          	auipc	ra,0x0
    80000eb2:	0c8080e7          	jalr	200(ra) # 80000f76 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000eb6:	00001097          	auipc	ra,0x1
    80000eba:	77c080e7          	jalr	1916(ra) # 80002632 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ebe:	00005097          	auipc	ra,0x5
    80000ec2:	cb2080e7          	jalr	-846(ra) # 80005b70 <plicinithart>
  }

  scheduler();        
    80000ec6:	00001097          	auipc	ra,0x1
    80000eca:	fc4080e7          	jalr	-60(ra) # 80001e8a <scheduler>
    consoleinit();
    80000ece:	fffff097          	auipc	ra,0xfffff
    80000ed2:	57c080e7          	jalr	1404(ra) # 8000044a <consoleinit>
    printfinit();
    80000ed6:	00000097          	auipc	ra,0x0
    80000eda:	88e080e7          	jalr	-1906(ra) # 80000764 <printfinit>
    printf("\n");
    80000ede:	00007517          	auipc	a0,0x7
    80000ee2:	20a50513          	addi	a0,a0,522 # 800080e8 <digits+0xa8>
    80000ee6:	fffff097          	auipc	ra,0xfffff
    80000eea:	69e080e7          	jalr	1694(ra) # 80000584 <printf>
    printf("EEE3535 Operating Systems: booting xv6-riscv kernel\n");
    80000eee:	00007517          	auipc	a0,0x7
    80000ef2:	1b250513          	addi	a0,a0,434 # 800080a0 <digits+0x60>
    80000ef6:	fffff097          	auipc	ra,0xfffff
    80000efa:	68e080e7          	jalr	1678(ra) # 80000584 <printf>
    kinit();         // physical page allocator
    80000efe:	00000097          	auipc	ra,0x0
    80000f02:	ba6080e7          	jalr	-1114(ra) # 80000aa4 <kinit>
    kvminit();       // create kernel page table
    80000f06:	00000097          	auipc	ra,0x0
    80000f0a:	326080e7          	jalr	806(ra) # 8000122c <kvminit>
    kvminithart();   // turn on paging
    80000f0e:	00000097          	auipc	ra,0x0
    80000f12:	068080e7          	jalr	104(ra) # 80000f76 <kvminithart>
    procinit();      // process table
    80000f16:	00001097          	auipc	ra,0x1
    80000f1a:	99e080e7          	jalr	-1634(ra) # 800018b4 <procinit>
    trapinit();      // trap vectors
    80000f1e:	00001097          	auipc	ra,0x1
    80000f22:	6ec080e7          	jalr	1772(ra) # 8000260a <trapinit>
    trapinithart();  // install kernel trap vector
    80000f26:	00001097          	auipc	ra,0x1
    80000f2a:	70c080e7          	jalr	1804(ra) # 80002632 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f2e:	00005097          	auipc	ra,0x5
    80000f32:	c2c080e7          	jalr	-980(ra) # 80005b5a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f36:	00005097          	auipc	ra,0x5
    80000f3a:	c3a080e7          	jalr	-966(ra) # 80005b70 <plicinithart>
    binit();         // buffer cache
    80000f3e:	00002097          	auipc	ra,0x2
    80000f42:	e34080e7          	jalr	-460(ra) # 80002d72 <binit>
    iinit();         // inode table
    80000f46:	00002097          	auipc	ra,0x2
    80000f4a:	4d2080e7          	jalr	1234(ra) # 80003418 <iinit>
    fileinit();      // file table
    80000f4e:	00003097          	auipc	ra,0x3
    80000f52:	448080e7          	jalr	1096(ra) # 80004396 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f56:	00005097          	auipc	ra,0x5
    80000f5a:	d22080e7          	jalr	-734(ra) # 80005c78 <virtio_disk_init>
    userinit();      // first user process
    80000f5e:	00001097          	auipc	ra,0x1
    80000f62:	d0e080e7          	jalr	-754(ra) # 80001c6c <userinit>
    __sync_synchronize();
    80000f66:	0ff0000f          	fence
    started = 1;
    80000f6a:	4785                	li	a5,1
    80000f6c:	00008717          	auipc	a4,0x8
    80000f70:	94f72e23          	sw	a5,-1700(a4) # 800088c8 <started>
    80000f74:	bf89                	j	80000ec6 <main+0x56>

0000000080000f76 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000f76:	1141                	addi	sp,sp,-16
    80000f78:	e422                	sd	s0,8(sp)
    80000f7a:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000f7c:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80000f80:	00008797          	auipc	a5,0x8
    80000f84:	9507b783          	ld	a5,-1712(a5) # 800088d0 <kernel_pagetable>
    80000f88:	83b1                	srli	a5,a5,0xc
    80000f8a:	577d                	li	a4,-1
    80000f8c:	177e                	slli	a4,a4,0x3f
    80000f8e:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000f90:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80000f94:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80000f98:	6422                	ld	s0,8(sp)
    80000f9a:	0141                	addi	sp,sp,16
    80000f9c:	8082                	ret

0000000080000f9e <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000f9e:	7139                	addi	sp,sp,-64
    80000fa0:	fc06                	sd	ra,56(sp)
    80000fa2:	f822                	sd	s0,48(sp)
    80000fa4:	f426                	sd	s1,40(sp)
    80000fa6:	f04a                	sd	s2,32(sp)
    80000fa8:	ec4e                	sd	s3,24(sp)
    80000faa:	e852                	sd	s4,16(sp)
    80000fac:	e456                	sd	s5,8(sp)
    80000fae:	e05a                	sd	s6,0(sp)
    80000fb0:	0080                	addi	s0,sp,64
    80000fb2:	84aa                	mv	s1,a0
    80000fb4:	89ae                	mv	s3,a1
    80000fb6:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fb8:	57fd                	li	a5,-1
    80000fba:	83e9                	srli	a5,a5,0x1a
    80000fbc:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fbe:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fc0:	04b7f263          	bgeu	a5,a1,80001004 <walk+0x66>
    panic("walk");
    80000fc4:	00007517          	auipc	a0,0x7
    80000fc8:	12c50513          	addi	a0,a0,300 # 800080f0 <digits+0xb0>
    80000fcc:	fffff097          	auipc	ra,0xfffff
    80000fd0:	56e080e7          	jalr	1390(ra) # 8000053a <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000fd4:	060a8663          	beqz	s5,80001040 <walk+0xa2>
    80000fd8:	00000097          	auipc	ra,0x0
    80000fdc:	b08080e7          	jalr	-1272(ra) # 80000ae0 <kalloc>
    80000fe0:	84aa                	mv	s1,a0
    80000fe2:	c529                	beqz	a0,8000102c <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80000fe4:	6605                	lui	a2,0x1
    80000fe6:	4581                	li	a1,0
    80000fe8:	00000097          	auipc	ra,0x0
    80000fec:	ce4080e7          	jalr	-796(ra) # 80000ccc <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80000ff0:	00c4d793          	srli	a5,s1,0xc
    80000ff4:	07aa                	slli	a5,a5,0xa
    80000ff6:	0017e793          	ori	a5,a5,1
    80000ffa:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80000ffe:	3a5d                	addiw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffdd297>
    80001000:	036a0063          	beq	s4,s6,80001020 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001004:	0149d933          	srl	s2,s3,s4
    80001008:	1ff97913          	andi	s2,s2,511
    8000100c:	090e                	slli	s2,s2,0x3
    8000100e:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001010:	00093483          	ld	s1,0(s2)
    80001014:	0014f793          	andi	a5,s1,1
    80001018:	dfd5                	beqz	a5,80000fd4 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    8000101a:	80a9                	srli	s1,s1,0xa
    8000101c:	04b2                	slli	s1,s1,0xc
    8000101e:	b7c5                	j	80000ffe <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001020:	00c9d513          	srli	a0,s3,0xc
    80001024:	1ff57513          	andi	a0,a0,511
    80001028:	050e                	slli	a0,a0,0x3
    8000102a:	9526                	add	a0,a0,s1
}
    8000102c:	70e2                	ld	ra,56(sp)
    8000102e:	7442                	ld	s0,48(sp)
    80001030:	74a2                	ld	s1,40(sp)
    80001032:	7902                	ld	s2,32(sp)
    80001034:	69e2                	ld	s3,24(sp)
    80001036:	6a42                	ld	s4,16(sp)
    80001038:	6aa2                	ld	s5,8(sp)
    8000103a:	6b02                	ld	s6,0(sp)
    8000103c:	6121                	addi	sp,sp,64
    8000103e:	8082                	ret
        return 0;
    80001040:	4501                	li	a0,0
    80001042:	b7ed                	j	8000102c <walk+0x8e>

0000000080001044 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001044:	57fd                	li	a5,-1
    80001046:	83e9                	srli	a5,a5,0x1a
    80001048:	00b7f463          	bgeu	a5,a1,80001050 <walkaddr+0xc>
    return 0;
    8000104c:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    8000104e:	8082                	ret
{
    80001050:	1141                	addi	sp,sp,-16
    80001052:	e406                	sd	ra,8(sp)
    80001054:	e022                	sd	s0,0(sp)
    80001056:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001058:	4601                	li	a2,0
    8000105a:	00000097          	auipc	ra,0x0
    8000105e:	f44080e7          	jalr	-188(ra) # 80000f9e <walk>
  if(pte == 0)
    80001062:	c105                	beqz	a0,80001082 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001064:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001066:	0117f693          	andi	a3,a5,17
    8000106a:	4745                	li	a4,17
    return 0;
    8000106c:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    8000106e:	00e68663          	beq	a3,a4,8000107a <walkaddr+0x36>
}
    80001072:	60a2                	ld	ra,8(sp)
    80001074:	6402                	ld	s0,0(sp)
    80001076:	0141                	addi	sp,sp,16
    80001078:	8082                	ret
  pa = PTE2PA(*pte);
    8000107a:	83a9                	srli	a5,a5,0xa
    8000107c:	00c79513          	slli	a0,a5,0xc
  return pa;
    80001080:	bfcd                	j	80001072 <walkaddr+0x2e>
    return 0;
    80001082:	4501                	li	a0,0
    80001084:	b7fd                	j	80001072 <walkaddr+0x2e>

0000000080001086 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    80001086:	715d                	addi	sp,sp,-80
    80001088:	e486                	sd	ra,72(sp)
    8000108a:	e0a2                	sd	s0,64(sp)
    8000108c:	fc26                	sd	s1,56(sp)
    8000108e:	f84a                	sd	s2,48(sp)
    80001090:	f44e                	sd	s3,40(sp)
    80001092:	f052                	sd	s4,32(sp)
    80001094:	ec56                	sd	s5,24(sp)
    80001096:	e85a                	sd	s6,16(sp)
    80001098:	e45e                	sd	s7,8(sp)
    8000109a:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    8000109c:	c639                	beqz	a2,800010ea <mappages+0x64>
    8000109e:	8aaa                	mv	s5,a0
    800010a0:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010a2:	777d                	lui	a4,0xfffff
    800010a4:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800010a8:	fff58993          	addi	s3,a1,-1
    800010ac:	99b2                	add	s3,s3,a2
    800010ae:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800010b2:	893e                	mv	s2,a5
    800010b4:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010b8:	6b85                	lui	s7,0x1
    800010ba:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800010be:	4605                	li	a2,1
    800010c0:	85ca                	mv	a1,s2
    800010c2:	8556                	mv	a0,s5
    800010c4:	00000097          	auipc	ra,0x0
    800010c8:	eda080e7          	jalr	-294(ra) # 80000f9e <walk>
    800010cc:	cd1d                	beqz	a0,8000110a <mappages+0x84>
    if(*pte & PTE_V)
    800010ce:	611c                	ld	a5,0(a0)
    800010d0:	8b85                	andi	a5,a5,1
    800010d2:	e785                	bnez	a5,800010fa <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800010d4:	80b1                	srli	s1,s1,0xc
    800010d6:	04aa                	slli	s1,s1,0xa
    800010d8:	0164e4b3          	or	s1,s1,s6
    800010dc:	0014e493          	ori	s1,s1,1
    800010e0:	e104                	sd	s1,0(a0)
    if(a == last)
    800010e2:	05390063          	beq	s2,s3,80001122 <mappages+0x9c>
    a += PGSIZE;
    800010e6:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    800010e8:	bfc9                	j	800010ba <mappages+0x34>
    panic("mappages: size");
    800010ea:	00007517          	auipc	a0,0x7
    800010ee:	00e50513          	addi	a0,a0,14 # 800080f8 <digits+0xb8>
    800010f2:	fffff097          	auipc	ra,0xfffff
    800010f6:	448080e7          	jalr	1096(ra) # 8000053a <panic>
      panic("mappages: remap");
    800010fa:	00007517          	auipc	a0,0x7
    800010fe:	00e50513          	addi	a0,a0,14 # 80008108 <digits+0xc8>
    80001102:	fffff097          	auipc	ra,0xfffff
    80001106:	438080e7          	jalr	1080(ra) # 8000053a <panic>
      return -1;
    8000110a:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    8000110c:	60a6                	ld	ra,72(sp)
    8000110e:	6406                	ld	s0,64(sp)
    80001110:	74e2                	ld	s1,56(sp)
    80001112:	7942                	ld	s2,48(sp)
    80001114:	79a2                	ld	s3,40(sp)
    80001116:	7a02                	ld	s4,32(sp)
    80001118:	6ae2                	ld	s5,24(sp)
    8000111a:	6b42                	ld	s6,16(sp)
    8000111c:	6ba2                	ld	s7,8(sp)
    8000111e:	6161                	addi	sp,sp,80
    80001120:	8082                	ret
  return 0;
    80001122:	4501                	li	a0,0
    80001124:	b7e5                	j	8000110c <mappages+0x86>

0000000080001126 <kvmmap>:
{
    80001126:	1141                	addi	sp,sp,-16
    80001128:	e406                	sd	ra,8(sp)
    8000112a:	e022                	sd	s0,0(sp)
    8000112c:	0800                	addi	s0,sp,16
    8000112e:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001130:	86b2                	mv	a3,a2
    80001132:	863e                	mv	a2,a5
    80001134:	00000097          	auipc	ra,0x0
    80001138:	f52080e7          	jalr	-174(ra) # 80001086 <mappages>
    8000113c:	e509                	bnez	a0,80001146 <kvmmap+0x20>
}
    8000113e:	60a2                	ld	ra,8(sp)
    80001140:	6402                	ld	s0,0(sp)
    80001142:	0141                	addi	sp,sp,16
    80001144:	8082                	ret
    panic("kvmmap");
    80001146:	00007517          	auipc	a0,0x7
    8000114a:	fd250513          	addi	a0,a0,-46 # 80008118 <digits+0xd8>
    8000114e:	fffff097          	auipc	ra,0xfffff
    80001152:	3ec080e7          	jalr	1004(ra) # 8000053a <panic>

0000000080001156 <kvmmake>:
{
    80001156:	1101                	addi	sp,sp,-32
    80001158:	ec06                	sd	ra,24(sp)
    8000115a:	e822                	sd	s0,16(sp)
    8000115c:	e426                	sd	s1,8(sp)
    8000115e:	e04a                	sd	s2,0(sp)
    80001160:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    80001162:	00000097          	auipc	ra,0x0
    80001166:	97e080e7          	jalr	-1666(ra) # 80000ae0 <kalloc>
    8000116a:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    8000116c:	6605                	lui	a2,0x1
    8000116e:	4581                	li	a1,0
    80001170:	00000097          	auipc	ra,0x0
    80001174:	b5c080e7          	jalr	-1188(ra) # 80000ccc <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001178:	4719                	li	a4,6
    8000117a:	6685                	lui	a3,0x1
    8000117c:	10000637          	lui	a2,0x10000
    80001180:	100005b7          	lui	a1,0x10000
    80001184:	8526                	mv	a0,s1
    80001186:	00000097          	auipc	ra,0x0
    8000118a:	fa0080e7          	jalr	-96(ra) # 80001126 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    8000118e:	4719                	li	a4,6
    80001190:	6685                	lui	a3,0x1
    80001192:	10001637          	lui	a2,0x10001
    80001196:	100015b7          	lui	a1,0x10001
    8000119a:	8526                	mv	a0,s1
    8000119c:	00000097          	auipc	ra,0x0
    800011a0:	f8a080e7          	jalr	-118(ra) # 80001126 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011a4:	4719                	li	a4,6
    800011a6:	004006b7          	lui	a3,0x400
    800011aa:	0c000637          	lui	a2,0xc000
    800011ae:	0c0005b7          	lui	a1,0xc000
    800011b2:	8526                	mv	a0,s1
    800011b4:	00000097          	auipc	ra,0x0
    800011b8:	f72080e7          	jalr	-142(ra) # 80001126 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011bc:	00007917          	auipc	s2,0x7
    800011c0:	e4490913          	addi	s2,s2,-444 # 80008000 <etext>
    800011c4:	4729                	li	a4,10
    800011c6:	80007697          	auipc	a3,0x80007
    800011ca:	e3a68693          	addi	a3,a3,-454 # 8000 <_entry-0x7fff8000>
    800011ce:	4605                	li	a2,1
    800011d0:	067e                	slli	a2,a2,0x1f
    800011d2:	85b2                	mv	a1,a2
    800011d4:	8526                	mv	a0,s1
    800011d6:	00000097          	auipc	ra,0x0
    800011da:	f50080e7          	jalr	-176(ra) # 80001126 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800011de:	4719                	li	a4,6
    800011e0:	46c5                	li	a3,17
    800011e2:	06ee                	slli	a3,a3,0x1b
    800011e4:	412686b3          	sub	a3,a3,s2
    800011e8:	864a                	mv	a2,s2
    800011ea:	85ca                	mv	a1,s2
    800011ec:	8526                	mv	a0,s1
    800011ee:	00000097          	auipc	ra,0x0
    800011f2:	f38080e7          	jalr	-200(ra) # 80001126 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    800011f6:	4729                	li	a4,10
    800011f8:	6685                	lui	a3,0x1
    800011fa:	00006617          	auipc	a2,0x6
    800011fe:	e0660613          	addi	a2,a2,-506 # 80007000 <_trampoline>
    80001202:	040005b7          	lui	a1,0x4000
    80001206:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001208:	05b2                	slli	a1,a1,0xc
    8000120a:	8526                	mv	a0,s1
    8000120c:	00000097          	auipc	ra,0x0
    80001210:	f1a080e7          	jalr	-230(ra) # 80001126 <kvmmap>
  proc_mapstacks(kpgtbl);
    80001214:	8526                	mv	a0,s1
    80001216:	00000097          	auipc	ra,0x0
    8000121a:	608080e7          	jalr	1544(ra) # 8000181e <proc_mapstacks>
}
    8000121e:	8526                	mv	a0,s1
    80001220:	60e2                	ld	ra,24(sp)
    80001222:	6442                	ld	s0,16(sp)
    80001224:	64a2                	ld	s1,8(sp)
    80001226:	6902                	ld	s2,0(sp)
    80001228:	6105                	addi	sp,sp,32
    8000122a:	8082                	ret

000000008000122c <kvminit>:
{
    8000122c:	1141                	addi	sp,sp,-16
    8000122e:	e406                	sd	ra,8(sp)
    80001230:	e022                	sd	s0,0(sp)
    80001232:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    80001234:	00000097          	auipc	ra,0x0
    80001238:	f22080e7          	jalr	-222(ra) # 80001156 <kvmmake>
    8000123c:	00007797          	auipc	a5,0x7
    80001240:	68a7ba23          	sd	a0,1684(a5) # 800088d0 <kernel_pagetable>
}
    80001244:	60a2                	ld	ra,8(sp)
    80001246:	6402                	ld	s0,0(sp)
    80001248:	0141                	addi	sp,sp,16
    8000124a:	8082                	ret

000000008000124c <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    8000124c:	715d                	addi	sp,sp,-80
    8000124e:	e486                	sd	ra,72(sp)
    80001250:	e0a2                	sd	s0,64(sp)
    80001252:	fc26                	sd	s1,56(sp)
    80001254:	f84a                	sd	s2,48(sp)
    80001256:	f44e                	sd	s3,40(sp)
    80001258:	f052                	sd	s4,32(sp)
    8000125a:	ec56                	sd	s5,24(sp)
    8000125c:	e85a                	sd	s6,16(sp)
    8000125e:	e45e                	sd	s7,8(sp)
    80001260:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001262:	03459793          	slli	a5,a1,0x34
    80001266:	e795                	bnez	a5,80001292 <uvmunmap+0x46>
    80001268:	8a2a                	mv	s4,a0
    8000126a:	892e                	mv	s2,a1
    8000126c:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000126e:	0632                	slli	a2,a2,0xc
    80001270:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    80001274:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001276:	6b05                	lui	s6,0x1
    80001278:	0735e263          	bltu	a1,s3,800012dc <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    8000127c:	60a6                	ld	ra,72(sp)
    8000127e:	6406                	ld	s0,64(sp)
    80001280:	74e2                	ld	s1,56(sp)
    80001282:	7942                	ld	s2,48(sp)
    80001284:	79a2                	ld	s3,40(sp)
    80001286:	7a02                	ld	s4,32(sp)
    80001288:	6ae2                	ld	s5,24(sp)
    8000128a:	6b42                	ld	s6,16(sp)
    8000128c:	6ba2                	ld	s7,8(sp)
    8000128e:	6161                	addi	sp,sp,80
    80001290:	8082                	ret
    panic("uvmunmap: not aligned");
    80001292:	00007517          	auipc	a0,0x7
    80001296:	e8e50513          	addi	a0,a0,-370 # 80008120 <digits+0xe0>
    8000129a:	fffff097          	auipc	ra,0xfffff
    8000129e:	2a0080e7          	jalr	672(ra) # 8000053a <panic>
      panic("uvmunmap: walk");
    800012a2:	00007517          	auipc	a0,0x7
    800012a6:	e9650513          	addi	a0,a0,-362 # 80008138 <digits+0xf8>
    800012aa:	fffff097          	auipc	ra,0xfffff
    800012ae:	290080e7          	jalr	656(ra) # 8000053a <panic>
      panic("uvmunmap: not mapped");
    800012b2:	00007517          	auipc	a0,0x7
    800012b6:	e9650513          	addi	a0,a0,-362 # 80008148 <digits+0x108>
    800012ba:	fffff097          	auipc	ra,0xfffff
    800012be:	280080e7          	jalr	640(ra) # 8000053a <panic>
      panic("uvmunmap: not a leaf");
    800012c2:	00007517          	auipc	a0,0x7
    800012c6:	e9e50513          	addi	a0,a0,-354 # 80008160 <digits+0x120>
    800012ca:	fffff097          	auipc	ra,0xfffff
    800012ce:	270080e7          	jalr	624(ra) # 8000053a <panic>
    *pte = 0;
    800012d2:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012d6:	995a                	add	s2,s2,s6
    800012d8:	fb3972e3          	bgeu	s2,s3,8000127c <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800012dc:	4601                	li	a2,0
    800012de:	85ca                	mv	a1,s2
    800012e0:	8552                	mv	a0,s4
    800012e2:	00000097          	auipc	ra,0x0
    800012e6:	cbc080e7          	jalr	-836(ra) # 80000f9e <walk>
    800012ea:	84aa                	mv	s1,a0
    800012ec:	d95d                	beqz	a0,800012a2 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    800012ee:	6108                	ld	a0,0(a0)
    800012f0:	00157793          	andi	a5,a0,1
    800012f4:	dfdd                	beqz	a5,800012b2 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    800012f6:	3ff57793          	andi	a5,a0,1023
    800012fa:	fd7784e3          	beq	a5,s7,800012c2 <uvmunmap+0x76>
    if(do_free){
    800012fe:	fc0a8ae3          	beqz	s5,800012d2 <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    80001302:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    80001304:	0532                	slli	a0,a0,0xc
    80001306:	fffff097          	auipc	ra,0xfffff
    8000130a:	6dc080e7          	jalr	1756(ra) # 800009e2 <kfree>
    8000130e:	b7d1                	j	800012d2 <uvmunmap+0x86>

0000000080001310 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001310:	1101                	addi	sp,sp,-32
    80001312:	ec06                	sd	ra,24(sp)
    80001314:	e822                	sd	s0,16(sp)
    80001316:	e426                	sd	s1,8(sp)
    80001318:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    8000131a:	fffff097          	auipc	ra,0xfffff
    8000131e:	7c6080e7          	jalr	1990(ra) # 80000ae0 <kalloc>
    80001322:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001324:	c519                	beqz	a0,80001332 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001326:	6605                	lui	a2,0x1
    80001328:	4581                	li	a1,0
    8000132a:	00000097          	auipc	ra,0x0
    8000132e:	9a2080e7          	jalr	-1630(ra) # 80000ccc <memset>
  return pagetable;
}
    80001332:	8526                	mv	a0,s1
    80001334:	60e2                	ld	ra,24(sp)
    80001336:	6442                	ld	s0,16(sp)
    80001338:	64a2                	ld	s1,8(sp)
    8000133a:	6105                	addi	sp,sp,32
    8000133c:	8082                	ret

000000008000133e <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    8000133e:	7179                	addi	sp,sp,-48
    80001340:	f406                	sd	ra,40(sp)
    80001342:	f022                	sd	s0,32(sp)
    80001344:	ec26                	sd	s1,24(sp)
    80001346:	e84a                	sd	s2,16(sp)
    80001348:	e44e                	sd	s3,8(sp)
    8000134a:	e052                	sd	s4,0(sp)
    8000134c:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    8000134e:	6785                	lui	a5,0x1
    80001350:	04f67863          	bgeu	a2,a5,800013a0 <uvmfirst+0x62>
    80001354:	8a2a                	mv	s4,a0
    80001356:	89ae                	mv	s3,a1
    80001358:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    8000135a:	fffff097          	auipc	ra,0xfffff
    8000135e:	786080e7          	jalr	1926(ra) # 80000ae0 <kalloc>
    80001362:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001364:	6605                	lui	a2,0x1
    80001366:	4581                	li	a1,0
    80001368:	00000097          	auipc	ra,0x0
    8000136c:	964080e7          	jalr	-1692(ra) # 80000ccc <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001370:	4779                	li	a4,30
    80001372:	86ca                	mv	a3,s2
    80001374:	6605                	lui	a2,0x1
    80001376:	4581                	li	a1,0
    80001378:	8552                	mv	a0,s4
    8000137a:	00000097          	auipc	ra,0x0
    8000137e:	d0c080e7          	jalr	-756(ra) # 80001086 <mappages>
  memmove(mem, src, sz);
    80001382:	8626                	mv	a2,s1
    80001384:	85ce                	mv	a1,s3
    80001386:	854a                	mv	a0,s2
    80001388:	00000097          	auipc	ra,0x0
    8000138c:	9a0080e7          	jalr	-1632(ra) # 80000d28 <memmove>
}
    80001390:	70a2                	ld	ra,40(sp)
    80001392:	7402                	ld	s0,32(sp)
    80001394:	64e2                	ld	s1,24(sp)
    80001396:	6942                	ld	s2,16(sp)
    80001398:	69a2                	ld	s3,8(sp)
    8000139a:	6a02                	ld	s4,0(sp)
    8000139c:	6145                	addi	sp,sp,48
    8000139e:	8082                	ret
    panic("uvmfirst: more than a page");
    800013a0:	00007517          	auipc	a0,0x7
    800013a4:	dd850513          	addi	a0,a0,-552 # 80008178 <digits+0x138>
    800013a8:	fffff097          	auipc	ra,0xfffff
    800013ac:	192080e7          	jalr	402(ra) # 8000053a <panic>

00000000800013b0 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013b0:	1101                	addi	sp,sp,-32
    800013b2:	ec06                	sd	ra,24(sp)
    800013b4:	e822                	sd	s0,16(sp)
    800013b6:	e426                	sd	s1,8(sp)
    800013b8:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013ba:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013bc:	00b67d63          	bgeu	a2,a1,800013d6 <uvmdealloc+0x26>
    800013c0:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013c2:	6785                	lui	a5,0x1
    800013c4:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800013c6:	00f60733          	add	a4,a2,a5
    800013ca:	76fd                	lui	a3,0xfffff
    800013cc:	8f75                	and	a4,a4,a3
    800013ce:	97ae                	add	a5,a5,a1
    800013d0:	8ff5                	and	a5,a5,a3
    800013d2:	00f76863          	bltu	a4,a5,800013e2 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800013d6:	8526                	mv	a0,s1
    800013d8:	60e2                	ld	ra,24(sp)
    800013da:	6442                	ld	s0,16(sp)
    800013dc:	64a2                	ld	s1,8(sp)
    800013de:	6105                	addi	sp,sp,32
    800013e0:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800013e2:	8f99                	sub	a5,a5,a4
    800013e4:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800013e6:	4685                	li	a3,1
    800013e8:	0007861b          	sext.w	a2,a5
    800013ec:	85ba                	mv	a1,a4
    800013ee:	00000097          	auipc	ra,0x0
    800013f2:	e5e080e7          	jalr	-418(ra) # 8000124c <uvmunmap>
    800013f6:	b7c5                	j	800013d6 <uvmdealloc+0x26>

00000000800013f8 <uvmalloc>:
  if(newsz < oldsz)
    800013f8:	0ab66563          	bltu	a2,a1,800014a2 <uvmalloc+0xaa>
{
    800013fc:	7139                	addi	sp,sp,-64
    800013fe:	fc06                	sd	ra,56(sp)
    80001400:	f822                	sd	s0,48(sp)
    80001402:	f426                	sd	s1,40(sp)
    80001404:	f04a                	sd	s2,32(sp)
    80001406:	ec4e                	sd	s3,24(sp)
    80001408:	e852                	sd	s4,16(sp)
    8000140a:	e456                	sd	s5,8(sp)
    8000140c:	e05a                	sd	s6,0(sp)
    8000140e:	0080                	addi	s0,sp,64
    80001410:	8aaa                	mv	s5,a0
    80001412:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001414:	6785                	lui	a5,0x1
    80001416:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001418:	95be                	add	a1,a1,a5
    8000141a:	77fd                	lui	a5,0xfffff
    8000141c:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001420:	08c9f363          	bgeu	s3,a2,800014a6 <uvmalloc+0xae>
    80001424:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    80001426:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    8000142a:	fffff097          	auipc	ra,0xfffff
    8000142e:	6b6080e7          	jalr	1718(ra) # 80000ae0 <kalloc>
    80001432:	84aa                	mv	s1,a0
    if(mem == 0){
    80001434:	c51d                	beqz	a0,80001462 <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    80001436:	6605                	lui	a2,0x1
    80001438:	4581                	li	a1,0
    8000143a:	00000097          	auipc	ra,0x0
    8000143e:	892080e7          	jalr	-1902(ra) # 80000ccc <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    80001442:	875a                	mv	a4,s6
    80001444:	86a6                	mv	a3,s1
    80001446:	6605                	lui	a2,0x1
    80001448:	85ca                	mv	a1,s2
    8000144a:	8556                	mv	a0,s5
    8000144c:	00000097          	auipc	ra,0x0
    80001450:	c3a080e7          	jalr	-966(ra) # 80001086 <mappages>
    80001454:	e90d                	bnez	a0,80001486 <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001456:	6785                	lui	a5,0x1
    80001458:	993e                	add	s2,s2,a5
    8000145a:	fd4968e3          	bltu	s2,s4,8000142a <uvmalloc+0x32>
  return newsz;
    8000145e:	8552                	mv	a0,s4
    80001460:	a809                	j	80001472 <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    80001462:	864e                	mv	a2,s3
    80001464:	85ca                	mv	a1,s2
    80001466:	8556                	mv	a0,s5
    80001468:	00000097          	auipc	ra,0x0
    8000146c:	f48080e7          	jalr	-184(ra) # 800013b0 <uvmdealloc>
      return 0;
    80001470:	4501                	li	a0,0
}
    80001472:	70e2                	ld	ra,56(sp)
    80001474:	7442                	ld	s0,48(sp)
    80001476:	74a2                	ld	s1,40(sp)
    80001478:	7902                	ld	s2,32(sp)
    8000147a:	69e2                	ld	s3,24(sp)
    8000147c:	6a42                	ld	s4,16(sp)
    8000147e:	6aa2                	ld	s5,8(sp)
    80001480:	6b02                	ld	s6,0(sp)
    80001482:	6121                	addi	sp,sp,64
    80001484:	8082                	ret
      kfree(mem);
    80001486:	8526                	mv	a0,s1
    80001488:	fffff097          	auipc	ra,0xfffff
    8000148c:	55a080e7          	jalr	1370(ra) # 800009e2 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001490:	864e                	mv	a2,s3
    80001492:	85ca                	mv	a1,s2
    80001494:	8556                	mv	a0,s5
    80001496:	00000097          	auipc	ra,0x0
    8000149a:	f1a080e7          	jalr	-230(ra) # 800013b0 <uvmdealloc>
      return 0;
    8000149e:	4501                	li	a0,0
    800014a0:	bfc9                	j	80001472 <uvmalloc+0x7a>
    return oldsz;
    800014a2:	852e                	mv	a0,a1
}
    800014a4:	8082                	ret
  return newsz;
    800014a6:	8532                	mv	a0,a2
    800014a8:	b7e9                	j	80001472 <uvmalloc+0x7a>

00000000800014aa <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014aa:	7179                	addi	sp,sp,-48
    800014ac:	f406                	sd	ra,40(sp)
    800014ae:	f022                	sd	s0,32(sp)
    800014b0:	ec26                	sd	s1,24(sp)
    800014b2:	e84a                	sd	s2,16(sp)
    800014b4:	e44e                	sd	s3,8(sp)
    800014b6:	e052                	sd	s4,0(sp)
    800014b8:	1800                	addi	s0,sp,48
    800014ba:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014bc:	84aa                	mv	s1,a0
    800014be:	6905                	lui	s2,0x1
    800014c0:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014c2:	4985                	li	s3,1
    800014c4:	a829                	j	800014de <freewalk+0x34>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014c6:	83a9                	srli	a5,a5,0xa
      freewalk((pagetable_t)child);
    800014c8:	00c79513          	slli	a0,a5,0xc
    800014cc:	00000097          	auipc	ra,0x0
    800014d0:	fde080e7          	jalr	-34(ra) # 800014aa <freewalk>
      pagetable[i] = 0;
    800014d4:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014d8:	04a1                	addi	s1,s1,8
    800014da:	03248163          	beq	s1,s2,800014fc <freewalk+0x52>
    pte_t pte = pagetable[i];
    800014de:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014e0:	00f7f713          	andi	a4,a5,15
    800014e4:	ff3701e3          	beq	a4,s3,800014c6 <freewalk+0x1c>
    } else if(pte & PTE_V){
    800014e8:	8b85                	andi	a5,a5,1
    800014ea:	d7fd                	beqz	a5,800014d8 <freewalk+0x2e>
      panic("freewalk: leaf");
    800014ec:	00007517          	auipc	a0,0x7
    800014f0:	cac50513          	addi	a0,a0,-852 # 80008198 <digits+0x158>
    800014f4:	fffff097          	auipc	ra,0xfffff
    800014f8:	046080e7          	jalr	70(ra) # 8000053a <panic>
    }
  }
  kfree((void*)pagetable);
    800014fc:	8552                	mv	a0,s4
    800014fe:	fffff097          	auipc	ra,0xfffff
    80001502:	4e4080e7          	jalr	1252(ra) # 800009e2 <kfree>
}
    80001506:	70a2                	ld	ra,40(sp)
    80001508:	7402                	ld	s0,32(sp)
    8000150a:	64e2                	ld	s1,24(sp)
    8000150c:	6942                	ld	s2,16(sp)
    8000150e:	69a2                	ld	s3,8(sp)
    80001510:	6a02                	ld	s4,0(sp)
    80001512:	6145                	addi	sp,sp,48
    80001514:	8082                	ret

0000000080001516 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001516:	1101                	addi	sp,sp,-32
    80001518:	ec06                	sd	ra,24(sp)
    8000151a:	e822                	sd	s0,16(sp)
    8000151c:	e426                	sd	s1,8(sp)
    8000151e:	1000                	addi	s0,sp,32
    80001520:	84aa                	mv	s1,a0
  if(sz > 0)
    80001522:	e999                	bnez	a1,80001538 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001524:	8526                	mv	a0,s1
    80001526:	00000097          	auipc	ra,0x0
    8000152a:	f84080e7          	jalr	-124(ra) # 800014aa <freewalk>
}
    8000152e:	60e2                	ld	ra,24(sp)
    80001530:	6442                	ld	s0,16(sp)
    80001532:	64a2                	ld	s1,8(sp)
    80001534:	6105                	addi	sp,sp,32
    80001536:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001538:	6785                	lui	a5,0x1
    8000153a:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    8000153c:	95be                	add	a1,a1,a5
    8000153e:	4685                	li	a3,1
    80001540:	00c5d613          	srli	a2,a1,0xc
    80001544:	4581                	li	a1,0
    80001546:	00000097          	auipc	ra,0x0
    8000154a:	d06080e7          	jalr	-762(ra) # 8000124c <uvmunmap>
    8000154e:	bfd9                	j	80001524 <uvmfree+0xe>

0000000080001550 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001550:	c679                	beqz	a2,8000161e <uvmcopy+0xce>
{
    80001552:	715d                	addi	sp,sp,-80
    80001554:	e486                	sd	ra,72(sp)
    80001556:	e0a2                	sd	s0,64(sp)
    80001558:	fc26                	sd	s1,56(sp)
    8000155a:	f84a                	sd	s2,48(sp)
    8000155c:	f44e                	sd	s3,40(sp)
    8000155e:	f052                	sd	s4,32(sp)
    80001560:	ec56                	sd	s5,24(sp)
    80001562:	e85a                	sd	s6,16(sp)
    80001564:	e45e                	sd	s7,8(sp)
    80001566:	0880                	addi	s0,sp,80
    80001568:	8b2a                	mv	s6,a0
    8000156a:	8aae                	mv	s5,a1
    8000156c:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    8000156e:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001570:	4601                	li	a2,0
    80001572:	85ce                	mv	a1,s3
    80001574:	855a                	mv	a0,s6
    80001576:	00000097          	auipc	ra,0x0
    8000157a:	a28080e7          	jalr	-1496(ra) # 80000f9e <walk>
    8000157e:	c531                	beqz	a0,800015ca <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001580:	6118                	ld	a4,0(a0)
    80001582:	00177793          	andi	a5,a4,1
    80001586:	cbb1                	beqz	a5,800015da <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    80001588:	00a75593          	srli	a1,a4,0xa
    8000158c:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    80001590:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    80001594:	fffff097          	auipc	ra,0xfffff
    80001598:	54c080e7          	jalr	1356(ra) # 80000ae0 <kalloc>
    8000159c:	892a                	mv	s2,a0
    8000159e:	c939                	beqz	a0,800015f4 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015a0:	6605                	lui	a2,0x1
    800015a2:	85de                	mv	a1,s7
    800015a4:	fffff097          	auipc	ra,0xfffff
    800015a8:	784080e7          	jalr	1924(ra) # 80000d28 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015ac:	8726                	mv	a4,s1
    800015ae:	86ca                	mv	a3,s2
    800015b0:	6605                	lui	a2,0x1
    800015b2:	85ce                	mv	a1,s3
    800015b4:	8556                	mv	a0,s5
    800015b6:	00000097          	auipc	ra,0x0
    800015ba:	ad0080e7          	jalr	-1328(ra) # 80001086 <mappages>
    800015be:	e515                	bnez	a0,800015ea <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015c0:	6785                	lui	a5,0x1
    800015c2:	99be                	add	s3,s3,a5
    800015c4:	fb49e6e3          	bltu	s3,s4,80001570 <uvmcopy+0x20>
    800015c8:	a081                	j	80001608 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015ca:	00007517          	auipc	a0,0x7
    800015ce:	bde50513          	addi	a0,a0,-1058 # 800081a8 <digits+0x168>
    800015d2:	fffff097          	auipc	ra,0xfffff
    800015d6:	f68080e7          	jalr	-152(ra) # 8000053a <panic>
      panic("uvmcopy: page not present");
    800015da:	00007517          	auipc	a0,0x7
    800015de:	bee50513          	addi	a0,a0,-1042 # 800081c8 <digits+0x188>
    800015e2:	fffff097          	auipc	ra,0xfffff
    800015e6:	f58080e7          	jalr	-168(ra) # 8000053a <panic>
      kfree(mem);
    800015ea:	854a                	mv	a0,s2
    800015ec:	fffff097          	auipc	ra,0xfffff
    800015f0:	3f6080e7          	jalr	1014(ra) # 800009e2 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    800015f4:	4685                	li	a3,1
    800015f6:	00c9d613          	srli	a2,s3,0xc
    800015fa:	4581                	li	a1,0
    800015fc:	8556                	mv	a0,s5
    800015fe:	00000097          	auipc	ra,0x0
    80001602:	c4e080e7          	jalr	-946(ra) # 8000124c <uvmunmap>
  return -1;
    80001606:	557d                	li	a0,-1
}
    80001608:	60a6                	ld	ra,72(sp)
    8000160a:	6406                	ld	s0,64(sp)
    8000160c:	74e2                	ld	s1,56(sp)
    8000160e:	7942                	ld	s2,48(sp)
    80001610:	79a2                	ld	s3,40(sp)
    80001612:	7a02                	ld	s4,32(sp)
    80001614:	6ae2                	ld	s5,24(sp)
    80001616:	6b42                	ld	s6,16(sp)
    80001618:	6ba2                	ld	s7,8(sp)
    8000161a:	6161                	addi	sp,sp,80
    8000161c:	8082                	ret
  return 0;
    8000161e:	4501                	li	a0,0
}
    80001620:	8082                	ret

0000000080001622 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001622:	1141                	addi	sp,sp,-16
    80001624:	e406                	sd	ra,8(sp)
    80001626:	e022                	sd	s0,0(sp)
    80001628:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    8000162a:	4601                	li	a2,0
    8000162c:	00000097          	auipc	ra,0x0
    80001630:	972080e7          	jalr	-1678(ra) # 80000f9e <walk>
  if(pte == 0)
    80001634:	c901                	beqz	a0,80001644 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001636:	611c                	ld	a5,0(a0)
    80001638:	9bbd                	andi	a5,a5,-17
    8000163a:	e11c                	sd	a5,0(a0)
}
    8000163c:	60a2                	ld	ra,8(sp)
    8000163e:	6402                	ld	s0,0(sp)
    80001640:	0141                	addi	sp,sp,16
    80001642:	8082                	ret
    panic("uvmclear");
    80001644:	00007517          	auipc	a0,0x7
    80001648:	ba450513          	addi	a0,a0,-1116 # 800081e8 <digits+0x1a8>
    8000164c:	fffff097          	auipc	ra,0xfffff
    80001650:	eee080e7          	jalr	-274(ra) # 8000053a <panic>

0000000080001654 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001654:	c6bd                	beqz	a3,800016c2 <copyout+0x6e>
{
    80001656:	715d                	addi	sp,sp,-80
    80001658:	e486                	sd	ra,72(sp)
    8000165a:	e0a2                	sd	s0,64(sp)
    8000165c:	fc26                	sd	s1,56(sp)
    8000165e:	f84a                	sd	s2,48(sp)
    80001660:	f44e                	sd	s3,40(sp)
    80001662:	f052                	sd	s4,32(sp)
    80001664:	ec56                	sd	s5,24(sp)
    80001666:	e85a                	sd	s6,16(sp)
    80001668:	e45e                	sd	s7,8(sp)
    8000166a:	e062                	sd	s8,0(sp)
    8000166c:	0880                	addi	s0,sp,80
    8000166e:	8b2a                	mv	s6,a0
    80001670:	8c2e                	mv	s8,a1
    80001672:	8a32                	mv	s4,a2
    80001674:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001676:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001678:	6a85                	lui	s5,0x1
    8000167a:	a015                	j	8000169e <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    8000167c:	9562                	add	a0,a0,s8
    8000167e:	0004861b          	sext.w	a2,s1
    80001682:	85d2                	mv	a1,s4
    80001684:	41250533          	sub	a0,a0,s2
    80001688:	fffff097          	auipc	ra,0xfffff
    8000168c:	6a0080e7          	jalr	1696(ra) # 80000d28 <memmove>

    len -= n;
    80001690:	409989b3          	sub	s3,s3,s1
    src += n;
    80001694:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    80001696:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000169a:	02098263          	beqz	s3,800016be <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    8000169e:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016a2:	85ca                	mv	a1,s2
    800016a4:	855a                	mv	a0,s6
    800016a6:	00000097          	auipc	ra,0x0
    800016aa:	99e080e7          	jalr	-1634(ra) # 80001044 <walkaddr>
    if(pa0 == 0)
    800016ae:	cd01                	beqz	a0,800016c6 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016b0:	418904b3          	sub	s1,s2,s8
    800016b4:	94d6                	add	s1,s1,s5
    800016b6:	fc99f3e3          	bgeu	s3,s1,8000167c <copyout+0x28>
    800016ba:	84ce                	mv	s1,s3
    800016bc:	b7c1                	j	8000167c <copyout+0x28>
  }
  return 0;
    800016be:	4501                	li	a0,0
    800016c0:	a021                	j	800016c8 <copyout+0x74>
    800016c2:	4501                	li	a0,0
}
    800016c4:	8082                	ret
      return -1;
    800016c6:	557d                	li	a0,-1
}
    800016c8:	60a6                	ld	ra,72(sp)
    800016ca:	6406                	ld	s0,64(sp)
    800016cc:	74e2                	ld	s1,56(sp)
    800016ce:	7942                	ld	s2,48(sp)
    800016d0:	79a2                	ld	s3,40(sp)
    800016d2:	7a02                	ld	s4,32(sp)
    800016d4:	6ae2                	ld	s5,24(sp)
    800016d6:	6b42                	ld	s6,16(sp)
    800016d8:	6ba2                	ld	s7,8(sp)
    800016da:	6c02                	ld	s8,0(sp)
    800016dc:	6161                	addi	sp,sp,80
    800016de:	8082                	ret

00000000800016e0 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016e0:	caa5                	beqz	a3,80001750 <copyin+0x70>
{
    800016e2:	715d                	addi	sp,sp,-80
    800016e4:	e486                	sd	ra,72(sp)
    800016e6:	e0a2                	sd	s0,64(sp)
    800016e8:	fc26                	sd	s1,56(sp)
    800016ea:	f84a                	sd	s2,48(sp)
    800016ec:	f44e                	sd	s3,40(sp)
    800016ee:	f052                	sd	s4,32(sp)
    800016f0:	ec56                	sd	s5,24(sp)
    800016f2:	e85a                	sd	s6,16(sp)
    800016f4:	e45e                	sd	s7,8(sp)
    800016f6:	e062                	sd	s8,0(sp)
    800016f8:	0880                	addi	s0,sp,80
    800016fa:	8b2a                	mv	s6,a0
    800016fc:	8a2e                	mv	s4,a1
    800016fe:	8c32                	mv	s8,a2
    80001700:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001702:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001704:	6a85                	lui	s5,0x1
    80001706:	a01d                	j	8000172c <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001708:	018505b3          	add	a1,a0,s8
    8000170c:	0004861b          	sext.w	a2,s1
    80001710:	412585b3          	sub	a1,a1,s2
    80001714:	8552                	mv	a0,s4
    80001716:	fffff097          	auipc	ra,0xfffff
    8000171a:	612080e7          	jalr	1554(ra) # 80000d28 <memmove>

    len -= n;
    8000171e:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001722:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001724:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001728:	02098263          	beqz	s3,8000174c <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    8000172c:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001730:	85ca                	mv	a1,s2
    80001732:	855a                	mv	a0,s6
    80001734:	00000097          	auipc	ra,0x0
    80001738:	910080e7          	jalr	-1776(ra) # 80001044 <walkaddr>
    if(pa0 == 0)
    8000173c:	cd01                	beqz	a0,80001754 <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    8000173e:	418904b3          	sub	s1,s2,s8
    80001742:	94d6                	add	s1,s1,s5
    80001744:	fc99f2e3          	bgeu	s3,s1,80001708 <copyin+0x28>
    80001748:	84ce                	mv	s1,s3
    8000174a:	bf7d                	j	80001708 <copyin+0x28>
  }
  return 0;
    8000174c:	4501                	li	a0,0
    8000174e:	a021                	j	80001756 <copyin+0x76>
    80001750:	4501                	li	a0,0
}
    80001752:	8082                	ret
      return -1;
    80001754:	557d                	li	a0,-1
}
    80001756:	60a6                	ld	ra,72(sp)
    80001758:	6406                	ld	s0,64(sp)
    8000175a:	74e2                	ld	s1,56(sp)
    8000175c:	7942                	ld	s2,48(sp)
    8000175e:	79a2                	ld	s3,40(sp)
    80001760:	7a02                	ld	s4,32(sp)
    80001762:	6ae2                	ld	s5,24(sp)
    80001764:	6b42                	ld	s6,16(sp)
    80001766:	6ba2                	ld	s7,8(sp)
    80001768:	6c02                	ld	s8,0(sp)
    8000176a:	6161                	addi	sp,sp,80
    8000176c:	8082                	ret

000000008000176e <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    8000176e:	c2dd                	beqz	a3,80001814 <copyinstr+0xa6>
{
    80001770:	715d                	addi	sp,sp,-80
    80001772:	e486                	sd	ra,72(sp)
    80001774:	e0a2                	sd	s0,64(sp)
    80001776:	fc26                	sd	s1,56(sp)
    80001778:	f84a                	sd	s2,48(sp)
    8000177a:	f44e                	sd	s3,40(sp)
    8000177c:	f052                	sd	s4,32(sp)
    8000177e:	ec56                	sd	s5,24(sp)
    80001780:	e85a                	sd	s6,16(sp)
    80001782:	e45e                	sd	s7,8(sp)
    80001784:	0880                	addi	s0,sp,80
    80001786:	8a2a                	mv	s4,a0
    80001788:	8b2e                	mv	s6,a1
    8000178a:	8bb2                	mv	s7,a2
    8000178c:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    8000178e:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001790:	6985                	lui	s3,0x1
    80001792:	a02d                	j	800017bc <copyinstr+0x4e>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    80001794:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    80001798:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    8000179a:	37fd                	addiw	a5,a5,-1
    8000179c:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017a0:	60a6                	ld	ra,72(sp)
    800017a2:	6406                	ld	s0,64(sp)
    800017a4:	74e2                	ld	s1,56(sp)
    800017a6:	7942                	ld	s2,48(sp)
    800017a8:	79a2                	ld	s3,40(sp)
    800017aa:	7a02                	ld	s4,32(sp)
    800017ac:	6ae2                	ld	s5,24(sp)
    800017ae:	6b42                	ld	s6,16(sp)
    800017b0:	6ba2                	ld	s7,8(sp)
    800017b2:	6161                	addi	sp,sp,80
    800017b4:	8082                	ret
    srcva = va0 + PGSIZE;
    800017b6:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017ba:	c8a9                	beqz	s1,8000180c <copyinstr+0x9e>
    va0 = PGROUNDDOWN(srcva);
    800017bc:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017c0:	85ca                	mv	a1,s2
    800017c2:	8552                	mv	a0,s4
    800017c4:	00000097          	auipc	ra,0x0
    800017c8:	880080e7          	jalr	-1920(ra) # 80001044 <walkaddr>
    if(pa0 == 0)
    800017cc:	c131                	beqz	a0,80001810 <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    800017ce:	417906b3          	sub	a3,s2,s7
    800017d2:	96ce                	add	a3,a3,s3
    800017d4:	00d4f363          	bgeu	s1,a3,800017da <copyinstr+0x6c>
    800017d8:	86a6                	mv	a3,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017da:	955e                	add	a0,a0,s7
    800017dc:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017e0:	daf9                	beqz	a3,800017b6 <copyinstr+0x48>
    800017e2:	87da                	mv	a5,s6
    800017e4:	885a                	mv	a6,s6
      if(*p == '\0'){
    800017e6:	41650633          	sub	a2,a0,s6
    while(n > 0){
    800017ea:	96da                	add	a3,a3,s6
    800017ec:	85be                	mv	a1,a5
      if(*p == '\0'){
    800017ee:	00f60733          	add	a4,a2,a5
    800017f2:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffdd2a0>
    800017f6:	df59                	beqz	a4,80001794 <copyinstr+0x26>
        *dst = *p;
    800017f8:	00e78023          	sb	a4,0(a5)
      dst++;
    800017fc:	0785                	addi	a5,a5,1
    while(n > 0){
    800017fe:	fed797e3          	bne	a5,a3,800017ec <copyinstr+0x7e>
    80001802:	14fd                	addi	s1,s1,-1
    80001804:	94c2                	add	s1,s1,a6
      --max;
    80001806:	8c8d                	sub	s1,s1,a1
      dst++;
    80001808:	8b3e                	mv	s6,a5
    8000180a:	b775                	j	800017b6 <copyinstr+0x48>
    8000180c:	4781                	li	a5,0
    8000180e:	b771                	j	8000179a <copyinstr+0x2c>
      return -1;
    80001810:	557d                	li	a0,-1
    80001812:	b779                	j	800017a0 <copyinstr+0x32>
  int got_null = 0;
    80001814:	4781                	li	a5,0
  if(got_null){
    80001816:	37fd                	addiw	a5,a5,-1
    80001818:	0007851b          	sext.w	a0,a5
}
    8000181c:	8082                	ret

000000008000181e <proc_mapstacks>:
// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl)
{
    8000181e:	7139                	addi	sp,sp,-64
    80001820:	fc06                	sd	ra,56(sp)
    80001822:	f822                	sd	s0,48(sp)
    80001824:	f426                	sd	s1,40(sp)
    80001826:	f04a                	sd	s2,32(sp)
    80001828:	ec4e                	sd	s3,24(sp)
    8000182a:	e852                	sd	s4,16(sp)
    8000182c:	e456                	sd	s5,8(sp)
    8000182e:	e05a                	sd	s6,0(sp)
    80001830:	0080                	addi	s0,sp,64
    80001832:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001834:	0000f497          	auipc	s1,0xf
    80001838:	74c48493          	addi	s1,s1,1868 # 80010f80 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    8000183c:	8b26                	mv	s6,s1
    8000183e:	00006a97          	auipc	s5,0x6
    80001842:	7c2a8a93          	addi	s5,s5,1986 # 80008000 <etext>
    80001846:	04000937          	lui	s2,0x4000
    8000184a:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    8000184c:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000184e:	00015a17          	auipc	s4,0x15
    80001852:	132a0a13          	addi	s4,s4,306 # 80016980 <tickslock>
    char *pa = kalloc();
    80001856:	fffff097          	auipc	ra,0xfffff
    8000185a:	28a080e7          	jalr	650(ra) # 80000ae0 <kalloc>
    8000185e:	862a                	mv	a2,a0
    if(pa == 0)
    80001860:	c131                	beqz	a0,800018a4 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001862:	416485b3          	sub	a1,s1,s6
    80001866:	858d                	srai	a1,a1,0x3
    80001868:	000ab783          	ld	a5,0(s5)
    8000186c:	02f585b3          	mul	a1,a1,a5
    80001870:	2585                	addiw	a1,a1,1
    80001872:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001876:	4719                	li	a4,6
    80001878:	6685                	lui	a3,0x1
    8000187a:	40b905b3          	sub	a1,s2,a1
    8000187e:	854e                	mv	a0,s3
    80001880:	00000097          	auipc	ra,0x0
    80001884:	8a6080e7          	jalr	-1882(ra) # 80001126 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001888:	16848493          	addi	s1,s1,360
    8000188c:	fd4495e3          	bne	s1,s4,80001856 <proc_mapstacks+0x38>
  }
}
    80001890:	70e2                	ld	ra,56(sp)
    80001892:	7442                	ld	s0,48(sp)
    80001894:	74a2                	ld	s1,40(sp)
    80001896:	7902                	ld	s2,32(sp)
    80001898:	69e2                	ld	s3,24(sp)
    8000189a:	6a42                	ld	s4,16(sp)
    8000189c:	6aa2                	ld	s5,8(sp)
    8000189e:	6b02                	ld	s6,0(sp)
    800018a0:	6121                	addi	sp,sp,64
    800018a2:	8082                	ret
      panic("kalloc");
    800018a4:	00007517          	auipc	a0,0x7
    800018a8:	95450513          	addi	a0,a0,-1708 # 800081f8 <digits+0x1b8>
    800018ac:	fffff097          	auipc	ra,0xfffff
    800018b0:	c8e080e7          	jalr	-882(ra) # 8000053a <panic>

00000000800018b4 <procinit>:

// initialize the proc table.
void
procinit(void)
{
    800018b4:	7139                	addi	sp,sp,-64
    800018b6:	fc06                	sd	ra,56(sp)
    800018b8:	f822                	sd	s0,48(sp)
    800018ba:	f426                	sd	s1,40(sp)
    800018bc:	f04a                	sd	s2,32(sp)
    800018be:	ec4e                	sd	s3,24(sp)
    800018c0:	e852                	sd	s4,16(sp)
    800018c2:	e456                	sd	s5,8(sp)
    800018c4:	e05a                	sd	s6,0(sp)
    800018c6:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    800018c8:	00007597          	auipc	a1,0x7
    800018cc:	93858593          	addi	a1,a1,-1736 # 80008200 <digits+0x1c0>
    800018d0:	0000f517          	auipc	a0,0xf
    800018d4:	28050513          	addi	a0,a0,640 # 80010b50 <pid_lock>
    800018d8:	fffff097          	auipc	ra,0xfffff
    800018dc:	268080e7          	jalr	616(ra) # 80000b40 <initlock>
  initlock(&wait_lock, "wait_lock");
    800018e0:	00007597          	auipc	a1,0x7
    800018e4:	92858593          	addi	a1,a1,-1752 # 80008208 <digits+0x1c8>
    800018e8:	0000f517          	auipc	a0,0xf
    800018ec:	28050513          	addi	a0,a0,640 # 80010b68 <wait_lock>
    800018f0:	fffff097          	auipc	ra,0xfffff
    800018f4:	250080e7          	jalr	592(ra) # 80000b40 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    800018f8:	0000f497          	auipc	s1,0xf
    800018fc:	68848493          	addi	s1,s1,1672 # 80010f80 <proc>
      initlock(&p->lock, "proc");
    80001900:	00007b17          	auipc	s6,0x7
    80001904:	918b0b13          	addi	s6,s6,-1768 # 80008218 <digits+0x1d8>
      p->state = UNUSED;
      p->kstack = KSTACK((int) (p - proc));
    80001908:	8aa6                	mv	s5,s1
    8000190a:	00006a17          	auipc	s4,0x6
    8000190e:	6f6a0a13          	addi	s4,s4,1782 # 80008000 <etext>
    80001912:	04000937          	lui	s2,0x4000
    80001916:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001918:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000191a:	00015997          	auipc	s3,0x15
    8000191e:	06698993          	addi	s3,s3,102 # 80016980 <tickslock>
      initlock(&p->lock, "proc");
    80001922:	85da                	mv	a1,s6
    80001924:	8526                	mv	a0,s1
    80001926:	fffff097          	auipc	ra,0xfffff
    8000192a:	21a080e7          	jalr	538(ra) # 80000b40 <initlock>
      p->state = UNUSED;
    8000192e:	0004ac23          	sw	zero,24(s1)
      p->kstack = KSTACK((int) (p - proc));
    80001932:	415487b3          	sub	a5,s1,s5
    80001936:	878d                	srai	a5,a5,0x3
    80001938:	000a3703          	ld	a4,0(s4)
    8000193c:	02e787b3          	mul	a5,a5,a4
    80001940:	2785                	addiw	a5,a5,1
    80001942:	00d7979b          	slliw	a5,a5,0xd
    80001946:	40f907b3          	sub	a5,s2,a5
    8000194a:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    8000194c:	16848493          	addi	s1,s1,360
    80001950:	fd3499e3          	bne	s1,s3,80001922 <procinit+0x6e>
  }
}
    80001954:	70e2                	ld	ra,56(sp)
    80001956:	7442                	ld	s0,48(sp)
    80001958:	74a2                	ld	s1,40(sp)
    8000195a:	7902                	ld	s2,32(sp)
    8000195c:	69e2                	ld	s3,24(sp)
    8000195e:	6a42                	ld	s4,16(sp)
    80001960:	6aa2                	ld	s5,8(sp)
    80001962:	6b02                	ld	s6,0(sp)
    80001964:	6121                	addi	sp,sp,64
    80001966:	8082                	ret

0000000080001968 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001968:	1141                	addi	sp,sp,-16
    8000196a:	e422                	sd	s0,8(sp)
    8000196c:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    8000196e:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001970:	2501                	sext.w	a0,a0
    80001972:	6422                	ld	s0,8(sp)
    80001974:	0141                	addi	sp,sp,16
    80001976:	8082                	ret

0000000080001978 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void)
{
    80001978:	1141                	addi	sp,sp,-16
    8000197a:	e422                	sd	s0,8(sp)
    8000197c:	0800                	addi	s0,sp,16
    8000197e:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001980:	2781                	sext.w	a5,a5
    80001982:	079e                	slli	a5,a5,0x7
  return c;
}
    80001984:	0000f517          	auipc	a0,0xf
    80001988:	1fc50513          	addi	a0,a0,508 # 80010b80 <cpus>
    8000198c:	953e                	add	a0,a0,a5
    8000198e:	6422                	ld	s0,8(sp)
    80001990:	0141                	addi	sp,sp,16
    80001992:	8082                	ret

0000000080001994 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void)
{
    80001994:	1101                	addi	sp,sp,-32
    80001996:	ec06                	sd	ra,24(sp)
    80001998:	e822                	sd	s0,16(sp)
    8000199a:	e426                	sd	s1,8(sp)
    8000199c:	1000                	addi	s0,sp,32
  push_off();
    8000199e:	fffff097          	auipc	ra,0xfffff
    800019a2:	1e6080e7          	jalr	486(ra) # 80000b84 <push_off>
    800019a6:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019a8:	2781                	sext.w	a5,a5
    800019aa:	079e                	slli	a5,a5,0x7
    800019ac:	0000f717          	auipc	a4,0xf
    800019b0:	1a470713          	addi	a4,a4,420 # 80010b50 <pid_lock>
    800019b4:	97ba                	add	a5,a5,a4
    800019b6:	7b84                	ld	s1,48(a5)
  pop_off();
    800019b8:	fffff097          	auipc	ra,0xfffff
    800019bc:	26c080e7          	jalr	620(ra) # 80000c24 <pop_off>
  return p;
}
    800019c0:	8526                	mv	a0,s1
    800019c2:	60e2                	ld	ra,24(sp)
    800019c4:	6442                	ld	s0,16(sp)
    800019c6:	64a2                	ld	s1,8(sp)
    800019c8:	6105                	addi	sp,sp,32
    800019ca:	8082                	ret

00000000800019cc <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    800019cc:	1141                	addi	sp,sp,-16
    800019ce:	e406                	sd	ra,8(sp)
    800019d0:	e022                	sd	s0,0(sp)
    800019d2:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    800019d4:	00000097          	auipc	ra,0x0
    800019d8:	fc0080e7          	jalr	-64(ra) # 80001994 <myproc>
    800019dc:	fffff097          	auipc	ra,0xfffff
    800019e0:	2a8080e7          	jalr	680(ra) # 80000c84 <release>

  if (first) {
    800019e4:	00007797          	auipc	a5,0x7
    800019e8:	e7c7a783          	lw	a5,-388(a5) # 80008860 <first.1>
    800019ec:	eb89                	bnez	a5,800019fe <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    800019ee:	00001097          	auipc	ra,0x1
    800019f2:	c5c080e7          	jalr	-932(ra) # 8000264a <usertrapret>
}
    800019f6:	60a2                	ld	ra,8(sp)
    800019f8:	6402                	ld	s0,0(sp)
    800019fa:	0141                	addi	sp,sp,16
    800019fc:	8082                	ret
    first = 0;
    800019fe:	00007797          	auipc	a5,0x7
    80001a02:	e607a123          	sw	zero,-414(a5) # 80008860 <first.1>
    fsinit(ROOTDEV);
    80001a06:	4505                	li	a0,1
    80001a08:	00002097          	auipc	ra,0x2
    80001a0c:	990080e7          	jalr	-1648(ra) # 80003398 <fsinit>
    80001a10:	bff9                	j	800019ee <forkret+0x22>

0000000080001a12 <allocpid>:
{
    80001a12:	1101                	addi	sp,sp,-32
    80001a14:	ec06                	sd	ra,24(sp)
    80001a16:	e822                	sd	s0,16(sp)
    80001a18:	e426                	sd	s1,8(sp)
    80001a1a:	e04a                	sd	s2,0(sp)
    80001a1c:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a1e:	0000f917          	auipc	s2,0xf
    80001a22:	13290913          	addi	s2,s2,306 # 80010b50 <pid_lock>
    80001a26:	854a                	mv	a0,s2
    80001a28:	fffff097          	auipc	ra,0xfffff
    80001a2c:	1a8080e7          	jalr	424(ra) # 80000bd0 <acquire>
  pid = nextpid;
    80001a30:	00007797          	auipc	a5,0x7
    80001a34:	e3478793          	addi	a5,a5,-460 # 80008864 <nextpid>
    80001a38:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a3a:	0014871b          	addiw	a4,s1,1
    80001a3e:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a40:	854a                	mv	a0,s2
    80001a42:	fffff097          	auipc	ra,0xfffff
    80001a46:	242080e7          	jalr	578(ra) # 80000c84 <release>
}
    80001a4a:	8526                	mv	a0,s1
    80001a4c:	60e2                	ld	ra,24(sp)
    80001a4e:	6442                	ld	s0,16(sp)
    80001a50:	64a2                	ld	s1,8(sp)
    80001a52:	6902                	ld	s2,0(sp)
    80001a54:	6105                	addi	sp,sp,32
    80001a56:	8082                	ret

0000000080001a58 <proc_pagetable>:
{
    80001a58:	1101                	addi	sp,sp,-32
    80001a5a:	ec06                	sd	ra,24(sp)
    80001a5c:	e822                	sd	s0,16(sp)
    80001a5e:	e426                	sd	s1,8(sp)
    80001a60:	e04a                	sd	s2,0(sp)
    80001a62:	1000                	addi	s0,sp,32
    80001a64:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a66:	00000097          	auipc	ra,0x0
    80001a6a:	8aa080e7          	jalr	-1878(ra) # 80001310 <uvmcreate>
    80001a6e:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001a70:	c121                	beqz	a0,80001ab0 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001a72:	4729                	li	a4,10
    80001a74:	00005697          	auipc	a3,0x5
    80001a78:	58c68693          	addi	a3,a3,1420 # 80007000 <_trampoline>
    80001a7c:	6605                	lui	a2,0x1
    80001a7e:	040005b7          	lui	a1,0x4000
    80001a82:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001a84:	05b2                	slli	a1,a1,0xc
    80001a86:	fffff097          	auipc	ra,0xfffff
    80001a8a:	600080e7          	jalr	1536(ra) # 80001086 <mappages>
    80001a8e:	02054863          	bltz	a0,80001abe <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001a92:	4719                	li	a4,6
    80001a94:	05893683          	ld	a3,88(s2)
    80001a98:	6605                	lui	a2,0x1
    80001a9a:	020005b7          	lui	a1,0x2000
    80001a9e:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001aa0:	05b6                	slli	a1,a1,0xd
    80001aa2:	8526                	mv	a0,s1
    80001aa4:	fffff097          	auipc	ra,0xfffff
    80001aa8:	5e2080e7          	jalr	1506(ra) # 80001086 <mappages>
    80001aac:	02054163          	bltz	a0,80001ace <proc_pagetable+0x76>
}
    80001ab0:	8526                	mv	a0,s1
    80001ab2:	60e2                	ld	ra,24(sp)
    80001ab4:	6442                	ld	s0,16(sp)
    80001ab6:	64a2                	ld	s1,8(sp)
    80001ab8:	6902                	ld	s2,0(sp)
    80001aba:	6105                	addi	sp,sp,32
    80001abc:	8082                	ret
    uvmfree(pagetable, 0);
    80001abe:	4581                	li	a1,0
    80001ac0:	8526                	mv	a0,s1
    80001ac2:	00000097          	auipc	ra,0x0
    80001ac6:	a54080e7          	jalr	-1452(ra) # 80001516 <uvmfree>
    return 0;
    80001aca:	4481                	li	s1,0
    80001acc:	b7d5                	j	80001ab0 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001ace:	4681                	li	a3,0
    80001ad0:	4605                	li	a2,1
    80001ad2:	040005b7          	lui	a1,0x4000
    80001ad6:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001ad8:	05b2                	slli	a1,a1,0xc
    80001ada:	8526                	mv	a0,s1
    80001adc:	fffff097          	auipc	ra,0xfffff
    80001ae0:	770080e7          	jalr	1904(ra) # 8000124c <uvmunmap>
    uvmfree(pagetable, 0);
    80001ae4:	4581                	li	a1,0
    80001ae6:	8526                	mv	a0,s1
    80001ae8:	00000097          	auipc	ra,0x0
    80001aec:	a2e080e7          	jalr	-1490(ra) # 80001516 <uvmfree>
    return 0;
    80001af0:	4481                	li	s1,0
    80001af2:	bf7d                	j	80001ab0 <proc_pagetable+0x58>

0000000080001af4 <proc_freepagetable>:
{
    80001af4:	1101                	addi	sp,sp,-32
    80001af6:	ec06                	sd	ra,24(sp)
    80001af8:	e822                	sd	s0,16(sp)
    80001afa:	e426                	sd	s1,8(sp)
    80001afc:	e04a                	sd	s2,0(sp)
    80001afe:	1000                	addi	s0,sp,32
    80001b00:	84aa                	mv	s1,a0
    80001b02:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b04:	4681                	li	a3,0
    80001b06:	4605                	li	a2,1
    80001b08:	040005b7          	lui	a1,0x4000
    80001b0c:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001b0e:	05b2                	slli	a1,a1,0xc
    80001b10:	fffff097          	auipc	ra,0xfffff
    80001b14:	73c080e7          	jalr	1852(ra) # 8000124c <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b18:	4681                	li	a3,0
    80001b1a:	4605                	li	a2,1
    80001b1c:	020005b7          	lui	a1,0x2000
    80001b20:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001b22:	05b6                	slli	a1,a1,0xd
    80001b24:	8526                	mv	a0,s1
    80001b26:	fffff097          	auipc	ra,0xfffff
    80001b2a:	726080e7          	jalr	1830(ra) # 8000124c <uvmunmap>
  uvmfree(pagetable, sz);
    80001b2e:	85ca                	mv	a1,s2
    80001b30:	8526                	mv	a0,s1
    80001b32:	00000097          	auipc	ra,0x0
    80001b36:	9e4080e7          	jalr	-1564(ra) # 80001516 <uvmfree>
}
    80001b3a:	60e2                	ld	ra,24(sp)
    80001b3c:	6442                	ld	s0,16(sp)
    80001b3e:	64a2                	ld	s1,8(sp)
    80001b40:	6902                	ld	s2,0(sp)
    80001b42:	6105                	addi	sp,sp,32
    80001b44:	8082                	ret

0000000080001b46 <freeproc>:
{
    80001b46:	1101                	addi	sp,sp,-32
    80001b48:	ec06                	sd	ra,24(sp)
    80001b4a:	e822                	sd	s0,16(sp)
    80001b4c:	e426                	sd	s1,8(sp)
    80001b4e:	1000                	addi	s0,sp,32
    80001b50:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001b52:	6d28                	ld	a0,88(a0)
    80001b54:	c509                	beqz	a0,80001b5e <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001b56:	fffff097          	auipc	ra,0xfffff
    80001b5a:	e8c080e7          	jalr	-372(ra) # 800009e2 <kfree>
  p->trapframe = 0;
    80001b5e:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001b62:	68a8                	ld	a0,80(s1)
    80001b64:	c511                	beqz	a0,80001b70 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001b66:	64ac                	ld	a1,72(s1)
    80001b68:	00000097          	auipc	ra,0x0
    80001b6c:	f8c080e7          	jalr	-116(ra) # 80001af4 <proc_freepagetable>
  p->pagetable = 0;
    80001b70:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001b74:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001b78:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001b7c:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001b80:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001b84:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001b88:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001b8c:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001b90:	0004ac23          	sw	zero,24(s1)
}
    80001b94:	60e2                	ld	ra,24(sp)
    80001b96:	6442                	ld	s0,16(sp)
    80001b98:	64a2                	ld	s1,8(sp)
    80001b9a:	6105                	addi	sp,sp,32
    80001b9c:	8082                	ret

0000000080001b9e <allocproc>:
{
    80001b9e:	1101                	addi	sp,sp,-32
    80001ba0:	ec06                	sd	ra,24(sp)
    80001ba2:	e822                	sd	s0,16(sp)
    80001ba4:	e426                	sd	s1,8(sp)
    80001ba6:	e04a                	sd	s2,0(sp)
    80001ba8:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001baa:	0000f497          	auipc	s1,0xf
    80001bae:	3d648493          	addi	s1,s1,982 # 80010f80 <proc>
    80001bb2:	00015917          	auipc	s2,0x15
    80001bb6:	dce90913          	addi	s2,s2,-562 # 80016980 <tickslock>
    acquire(&p->lock);
    80001bba:	8526                	mv	a0,s1
    80001bbc:	fffff097          	auipc	ra,0xfffff
    80001bc0:	014080e7          	jalr	20(ra) # 80000bd0 <acquire>
    if(p->state == UNUSED) {
    80001bc4:	4c9c                	lw	a5,24(s1)
    80001bc6:	cf81                	beqz	a5,80001bde <allocproc+0x40>
      release(&p->lock);
    80001bc8:	8526                	mv	a0,s1
    80001bca:	fffff097          	auipc	ra,0xfffff
    80001bce:	0ba080e7          	jalr	186(ra) # 80000c84 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bd2:	16848493          	addi	s1,s1,360
    80001bd6:	ff2492e3          	bne	s1,s2,80001bba <allocproc+0x1c>
  return 0;
    80001bda:	4481                	li	s1,0
    80001bdc:	a889                	j	80001c2e <allocproc+0x90>
  p->pid = allocpid();
    80001bde:	00000097          	auipc	ra,0x0
    80001be2:	e34080e7          	jalr	-460(ra) # 80001a12 <allocpid>
    80001be6:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001be8:	4785                	li	a5,1
    80001bea:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001bec:	fffff097          	auipc	ra,0xfffff
    80001bf0:	ef4080e7          	jalr	-268(ra) # 80000ae0 <kalloc>
    80001bf4:	892a                	mv	s2,a0
    80001bf6:	eca8                	sd	a0,88(s1)
    80001bf8:	c131                	beqz	a0,80001c3c <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    80001bfa:	8526                	mv	a0,s1
    80001bfc:	00000097          	auipc	ra,0x0
    80001c00:	e5c080e7          	jalr	-420(ra) # 80001a58 <proc_pagetable>
    80001c04:	892a                	mv	s2,a0
    80001c06:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c08:	c531                	beqz	a0,80001c54 <allocproc+0xb6>
  memset(&p->context, 0, sizeof(p->context));
    80001c0a:	07000613          	li	a2,112
    80001c0e:	4581                	li	a1,0
    80001c10:	06048513          	addi	a0,s1,96
    80001c14:	fffff097          	auipc	ra,0xfffff
    80001c18:	0b8080e7          	jalr	184(ra) # 80000ccc <memset>
  p->context.ra = (uint64)forkret;
    80001c1c:	00000797          	auipc	a5,0x0
    80001c20:	db078793          	addi	a5,a5,-592 # 800019cc <forkret>
    80001c24:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c26:	60bc                	ld	a5,64(s1)
    80001c28:	6705                	lui	a4,0x1
    80001c2a:	97ba                	add	a5,a5,a4
    80001c2c:	f4bc                	sd	a5,104(s1)
}
    80001c2e:	8526                	mv	a0,s1
    80001c30:	60e2                	ld	ra,24(sp)
    80001c32:	6442                	ld	s0,16(sp)
    80001c34:	64a2                	ld	s1,8(sp)
    80001c36:	6902                	ld	s2,0(sp)
    80001c38:	6105                	addi	sp,sp,32
    80001c3a:	8082                	ret
    freeproc(p);
    80001c3c:	8526                	mv	a0,s1
    80001c3e:	00000097          	auipc	ra,0x0
    80001c42:	f08080e7          	jalr	-248(ra) # 80001b46 <freeproc>
    release(&p->lock);
    80001c46:	8526                	mv	a0,s1
    80001c48:	fffff097          	auipc	ra,0xfffff
    80001c4c:	03c080e7          	jalr	60(ra) # 80000c84 <release>
    return 0;
    80001c50:	84ca                	mv	s1,s2
    80001c52:	bff1                	j	80001c2e <allocproc+0x90>
    freeproc(p);
    80001c54:	8526                	mv	a0,s1
    80001c56:	00000097          	auipc	ra,0x0
    80001c5a:	ef0080e7          	jalr	-272(ra) # 80001b46 <freeproc>
    release(&p->lock);
    80001c5e:	8526                	mv	a0,s1
    80001c60:	fffff097          	auipc	ra,0xfffff
    80001c64:	024080e7          	jalr	36(ra) # 80000c84 <release>
    return 0;
    80001c68:	84ca                	mv	s1,s2
    80001c6a:	b7d1                	j	80001c2e <allocproc+0x90>

0000000080001c6c <userinit>:
{
    80001c6c:	1101                	addi	sp,sp,-32
    80001c6e:	ec06                	sd	ra,24(sp)
    80001c70:	e822                	sd	s0,16(sp)
    80001c72:	e426                	sd	s1,8(sp)
    80001c74:	1000                	addi	s0,sp,32
  p = allocproc();
    80001c76:	00000097          	auipc	ra,0x0
    80001c7a:	f28080e7          	jalr	-216(ra) # 80001b9e <allocproc>
    80001c7e:	84aa                	mv	s1,a0
  initproc = p;
    80001c80:	00007797          	auipc	a5,0x7
    80001c84:	c4a7bc23          	sd	a0,-936(a5) # 800088d8 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001c88:	03400613          	li	a2,52
    80001c8c:	00007597          	auipc	a1,0x7
    80001c90:	be458593          	addi	a1,a1,-1052 # 80008870 <initcode>
    80001c94:	6928                	ld	a0,80(a0)
    80001c96:	fffff097          	auipc	ra,0xfffff
    80001c9a:	6a8080e7          	jalr	1704(ra) # 8000133e <uvmfirst>
  p->sz = PGSIZE;
    80001c9e:	6785                	lui	a5,0x1
    80001ca0:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001ca2:	6cb8                	ld	a4,88(s1)
    80001ca4:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001ca8:	6cb8                	ld	a4,88(s1)
    80001caa:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cac:	4641                	li	a2,16
    80001cae:	00006597          	auipc	a1,0x6
    80001cb2:	57258593          	addi	a1,a1,1394 # 80008220 <digits+0x1e0>
    80001cb6:	15848513          	addi	a0,s1,344
    80001cba:	fffff097          	auipc	ra,0xfffff
    80001cbe:	15a080e7          	jalr	346(ra) # 80000e14 <safestrcpy>
  p->cwd = namei("/");
    80001cc2:	00006517          	auipc	a0,0x6
    80001cc6:	56e50513          	addi	a0,a0,1390 # 80008230 <digits+0x1f0>
    80001cca:	00002097          	auipc	ra,0x2
    80001cce:	0ec080e7          	jalr	236(ra) # 80003db6 <namei>
    80001cd2:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001cd6:	478d                	li	a5,3
    80001cd8:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001cda:	8526                	mv	a0,s1
    80001cdc:	fffff097          	auipc	ra,0xfffff
    80001ce0:	fa8080e7          	jalr	-88(ra) # 80000c84 <release>
}
    80001ce4:	60e2                	ld	ra,24(sp)
    80001ce6:	6442                	ld	s0,16(sp)
    80001ce8:	64a2                	ld	s1,8(sp)
    80001cea:	6105                	addi	sp,sp,32
    80001cec:	8082                	ret

0000000080001cee <growproc>:
{
    80001cee:	1101                	addi	sp,sp,-32
    80001cf0:	ec06                	sd	ra,24(sp)
    80001cf2:	e822                	sd	s0,16(sp)
    80001cf4:	e426                	sd	s1,8(sp)
    80001cf6:	e04a                	sd	s2,0(sp)
    80001cf8:	1000                	addi	s0,sp,32
    80001cfa:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001cfc:	00000097          	auipc	ra,0x0
    80001d00:	c98080e7          	jalr	-872(ra) # 80001994 <myproc>
    80001d04:	84aa                	mv	s1,a0
  sz = p->sz;
    80001d06:	652c                	ld	a1,72(a0)
  if(n > 0){
    80001d08:	01204c63          	bgtz	s2,80001d20 <growproc+0x32>
  } else if(n < 0){
    80001d0c:	02094663          	bltz	s2,80001d38 <growproc+0x4a>
  p->sz = sz;
    80001d10:	e4ac                	sd	a1,72(s1)
  return 0;
    80001d12:	4501                	li	a0,0
}
    80001d14:	60e2                	ld	ra,24(sp)
    80001d16:	6442                	ld	s0,16(sp)
    80001d18:	64a2                	ld	s1,8(sp)
    80001d1a:	6902                	ld	s2,0(sp)
    80001d1c:	6105                	addi	sp,sp,32
    80001d1e:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0) {
    80001d20:	4691                	li	a3,4
    80001d22:	00b90633          	add	a2,s2,a1
    80001d26:	6928                	ld	a0,80(a0)
    80001d28:	fffff097          	auipc	ra,0xfffff
    80001d2c:	6d0080e7          	jalr	1744(ra) # 800013f8 <uvmalloc>
    80001d30:	85aa                	mv	a1,a0
    80001d32:	fd79                	bnez	a0,80001d10 <growproc+0x22>
      return -1;
    80001d34:	557d                	li	a0,-1
    80001d36:	bff9                	j	80001d14 <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d38:	00b90633          	add	a2,s2,a1
    80001d3c:	6928                	ld	a0,80(a0)
    80001d3e:	fffff097          	auipc	ra,0xfffff
    80001d42:	672080e7          	jalr	1650(ra) # 800013b0 <uvmdealloc>
    80001d46:	85aa                	mv	a1,a0
    80001d48:	b7e1                	j	80001d10 <growproc+0x22>

0000000080001d4a <fork>:
{
    80001d4a:	7139                	addi	sp,sp,-64
    80001d4c:	fc06                	sd	ra,56(sp)
    80001d4e:	f822                	sd	s0,48(sp)
    80001d50:	f426                	sd	s1,40(sp)
    80001d52:	f04a                	sd	s2,32(sp)
    80001d54:	ec4e                	sd	s3,24(sp)
    80001d56:	e852                	sd	s4,16(sp)
    80001d58:	e456                	sd	s5,8(sp)
    80001d5a:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001d5c:	00000097          	auipc	ra,0x0
    80001d60:	c38080e7          	jalr	-968(ra) # 80001994 <myproc>
    80001d64:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001d66:	00000097          	auipc	ra,0x0
    80001d6a:	e38080e7          	jalr	-456(ra) # 80001b9e <allocproc>
    80001d6e:	10050c63          	beqz	a0,80001e86 <fork+0x13c>
    80001d72:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001d74:	048ab603          	ld	a2,72(s5)
    80001d78:	692c                	ld	a1,80(a0)
    80001d7a:	050ab503          	ld	a0,80(s5)
    80001d7e:	fffff097          	auipc	ra,0xfffff
    80001d82:	7d2080e7          	jalr	2002(ra) # 80001550 <uvmcopy>
    80001d86:	04054863          	bltz	a0,80001dd6 <fork+0x8c>
  np->sz = p->sz;
    80001d8a:	048ab783          	ld	a5,72(s5)
    80001d8e:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80001d92:	058ab683          	ld	a3,88(s5)
    80001d96:	87b6                	mv	a5,a3
    80001d98:	058a3703          	ld	a4,88(s4)
    80001d9c:	12068693          	addi	a3,a3,288
    80001da0:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001da4:	6788                	ld	a0,8(a5)
    80001da6:	6b8c                	ld	a1,16(a5)
    80001da8:	6f90                	ld	a2,24(a5)
    80001daa:	01073023          	sd	a6,0(a4)
    80001dae:	e708                	sd	a0,8(a4)
    80001db0:	eb0c                	sd	a1,16(a4)
    80001db2:	ef10                	sd	a2,24(a4)
    80001db4:	02078793          	addi	a5,a5,32
    80001db8:	02070713          	addi	a4,a4,32
    80001dbc:	fed792e3          	bne	a5,a3,80001da0 <fork+0x56>
  np->trapframe->a0 = 0;
    80001dc0:	058a3783          	ld	a5,88(s4)
    80001dc4:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001dc8:	0d0a8493          	addi	s1,s5,208
    80001dcc:	0d0a0913          	addi	s2,s4,208
    80001dd0:	150a8993          	addi	s3,s5,336
    80001dd4:	a00d                	j	80001df6 <fork+0xac>
    freeproc(np);
    80001dd6:	8552                	mv	a0,s4
    80001dd8:	00000097          	auipc	ra,0x0
    80001ddc:	d6e080e7          	jalr	-658(ra) # 80001b46 <freeproc>
    release(&np->lock);
    80001de0:	8552                	mv	a0,s4
    80001de2:	fffff097          	auipc	ra,0xfffff
    80001de6:	ea2080e7          	jalr	-350(ra) # 80000c84 <release>
    return -1;
    80001dea:	597d                	li	s2,-1
    80001dec:	a059                	j	80001e72 <fork+0x128>
  for(i = 0; i < NOFILE; i++)
    80001dee:	04a1                	addi	s1,s1,8
    80001df0:	0921                	addi	s2,s2,8
    80001df2:	01348b63          	beq	s1,s3,80001e08 <fork+0xbe>
    if(p->ofile[i])
    80001df6:	6088                	ld	a0,0(s1)
    80001df8:	d97d                	beqz	a0,80001dee <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001dfa:	00002097          	auipc	ra,0x2
    80001dfe:	62e080e7          	jalr	1582(ra) # 80004428 <filedup>
    80001e02:	00a93023          	sd	a0,0(s2)
    80001e06:	b7e5                	j	80001dee <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001e08:	150ab503          	ld	a0,336(s5)
    80001e0c:	00001097          	auipc	ra,0x1
    80001e10:	7c6080e7          	jalr	1990(ra) # 800035d2 <idup>
    80001e14:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e18:	4641                	li	a2,16
    80001e1a:	158a8593          	addi	a1,s5,344
    80001e1e:	158a0513          	addi	a0,s4,344
    80001e22:	fffff097          	auipc	ra,0xfffff
    80001e26:	ff2080e7          	jalr	-14(ra) # 80000e14 <safestrcpy>
  pid = np->pid;
    80001e2a:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80001e2e:	8552                	mv	a0,s4
    80001e30:	fffff097          	auipc	ra,0xfffff
    80001e34:	e54080e7          	jalr	-428(ra) # 80000c84 <release>
  acquire(&wait_lock);
    80001e38:	0000f497          	auipc	s1,0xf
    80001e3c:	d3048493          	addi	s1,s1,-720 # 80010b68 <wait_lock>
    80001e40:	8526                	mv	a0,s1
    80001e42:	fffff097          	auipc	ra,0xfffff
    80001e46:	d8e080e7          	jalr	-626(ra) # 80000bd0 <acquire>
  np->parent = p;
    80001e4a:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80001e4e:	8526                	mv	a0,s1
    80001e50:	fffff097          	auipc	ra,0xfffff
    80001e54:	e34080e7          	jalr	-460(ra) # 80000c84 <release>
  acquire(&np->lock);
    80001e58:	8552                	mv	a0,s4
    80001e5a:	fffff097          	auipc	ra,0xfffff
    80001e5e:	d76080e7          	jalr	-650(ra) # 80000bd0 <acquire>
  np->state = RUNNABLE;
    80001e62:	478d                	li	a5,3
    80001e64:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001e68:	8552                	mv	a0,s4
    80001e6a:	fffff097          	auipc	ra,0xfffff
    80001e6e:	e1a080e7          	jalr	-486(ra) # 80000c84 <release>
}
    80001e72:	854a                	mv	a0,s2
    80001e74:	70e2                	ld	ra,56(sp)
    80001e76:	7442                	ld	s0,48(sp)
    80001e78:	74a2                	ld	s1,40(sp)
    80001e7a:	7902                	ld	s2,32(sp)
    80001e7c:	69e2                	ld	s3,24(sp)
    80001e7e:	6a42                	ld	s4,16(sp)
    80001e80:	6aa2                	ld	s5,8(sp)
    80001e82:	6121                	addi	sp,sp,64
    80001e84:	8082                	ret
    return -1;
    80001e86:	597d                	li	s2,-1
    80001e88:	b7ed                	j	80001e72 <fork+0x128>

0000000080001e8a <scheduler>:
{
    80001e8a:	7139                	addi	sp,sp,-64
    80001e8c:	fc06                	sd	ra,56(sp)
    80001e8e:	f822                	sd	s0,48(sp)
    80001e90:	f426                	sd	s1,40(sp)
    80001e92:	f04a                	sd	s2,32(sp)
    80001e94:	ec4e                	sd	s3,24(sp)
    80001e96:	e852                	sd	s4,16(sp)
    80001e98:	e456                	sd	s5,8(sp)
    80001e9a:	e05a                	sd	s6,0(sp)
    80001e9c:	0080                	addi	s0,sp,64
    80001e9e:	8792                	mv	a5,tp
  int id = r_tp();
    80001ea0:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001ea2:	00779a93          	slli	s5,a5,0x7
    80001ea6:	0000f717          	auipc	a4,0xf
    80001eaa:	caa70713          	addi	a4,a4,-854 # 80010b50 <pid_lock>
    80001eae:	9756                	add	a4,a4,s5
    80001eb0:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001eb4:	0000f717          	auipc	a4,0xf
    80001eb8:	cd470713          	addi	a4,a4,-812 # 80010b88 <cpus+0x8>
    80001ebc:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80001ebe:	498d                	li	s3,3
        p->state = RUNNING;
    80001ec0:	4b11                	li	s6,4
        c->proc = p;
    80001ec2:	079e                	slli	a5,a5,0x7
    80001ec4:	0000fa17          	auipc	s4,0xf
    80001ec8:	c8ca0a13          	addi	s4,s4,-884 # 80010b50 <pid_lock>
    80001ecc:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001ece:	00015917          	auipc	s2,0x15
    80001ed2:	ab290913          	addi	s2,s2,-1358 # 80016980 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001ed6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001eda:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001ede:	10079073          	csrw	sstatus,a5
    80001ee2:	0000f497          	auipc	s1,0xf
    80001ee6:	09e48493          	addi	s1,s1,158 # 80010f80 <proc>
    80001eea:	a811                	j	80001efe <scheduler+0x74>
      release(&p->lock);
    80001eec:	8526                	mv	a0,s1
    80001eee:	fffff097          	auipc	ra,0xfffff
    80001ef2:	d96080e7          	jalr	-618(ra) # 80000c84 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001ef6:	16848493          	addi	s1,s1,360
    80001efa:	fd248ee3          	beq	s1,s2,80001ed6 <scheduler+0x4c>
      acquire(&p->lock);
    80001efe:	8526                	mv	a0,s1
    80001f00:	fffff097          	auipc	ra,0xfffff
    80001f04:	cd0080e7          	jalr	-816(ra) # 80000bd0 <acquire>
      if(p->state == RUNNABLE) {
    80001f08:	4c9c                	lw	a5,24(s1)
    80001f0a:	ff3791e3          	bne	a5,s3,80001eec <scheduler+0x62>
        p->state = RUNNING;
    80001f0e:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80001f12:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001f16:	06048593          	addi	a1,s1,96
    80001f1a:	8556                	mv	a0,s5
    80001f1c:	00000097          	auipc	ra,0x0
    80001f20:	684080e7          	jalr	1668(ra) # 800025a0 <swtch>
        c->proc = 0;
    80001f24:	020a3823          	sd	zero,48(s4)
    80001f28:	b7d1                	j	80001eec <scheduler+0x62>

0000000080001f2a <sched>:
{
    80001f2a:	7179                	addi	sp,sp,-48
    80001f2c:	f406                	sd	ra,40(sp)
    80001f2e:	f022                	sd	s0,32(sp)
    80001f30:	ec26                	sd	s1,24(sp)
    80001f32:	e84a                	sd	s2,16(sp)
    80001f34:	e44e                	sd	s3,8(sp)
    80001f36:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001f38:	00000097          	auipc	ra,0x0
    80001f3c:	a5c080e7          	jalr	-1444(ra) # 80001994 <myproc>
    80001f40:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001f42:	fffff097          	auipc	ra,0xfffff
    80001f46:	c14080e7          	jalr	-1004(ra) # 80000b56 <holding>
    80001f4a:	c93d                	beqz	a0,80001fc0 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f4c:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001f4e:	2781                	sext.w	a5,a5
    80001f50:	079e                	slli	a5,a5,0x7
    80001f52:	0000f717          	auipc	a4,0xf
    80001f56:	bfe70713          	addi	a4,a4,-1026 # 80010b50 <pid_lock>
    80001f5a:	97ba                	add	a5,a5,a4
    80001f5c:	0a87a703          	lw	a4,168(a5)
    80001f60:	4785                	li	a5,1
    80001f62:	06f71763          	bne	a4,a5,80001fd0 <sched+0xa6>
  if(p->state == RUNNING)
    80001f66:	4c98                	lw	a4,24(s1)
    80001f68:	4791                	li	a5,4
    80001f6a:	06f70b63          	beq	a4,a5,80001fe0 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f6e:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001f72:	8b89                	andi	a5,a5,2
  if(intr_get())
    80001f74:	efb5                	bnez	a5,80001ff0 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f76:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001f78:	0000f917          	auipc	s2,0xf
    80001f7c:	bd890913          	addi	s2,s2,-1064 # 80010b50 <pid_lock>
    80001f80:	2781                	sext.w	a5,a5
    80001f82:	079e                	slli	a5,a5,0x7
    80001f84:	97ca                	add	a5,a5,s2
    80001f86:	0ac7a983          	lw	s3,172(a5)
    80001f8a:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001f8c:	2781                	sext.w	a5,a5
    80001f8e:	079e                	slli	a5,a5,0x7
    80001f90:	0000f597          	auipc	a1,0xf
    80001f94:	bf858593          	addi	a1,a1,-1032 # 80010b88 <cpus+0x8>
    80001f98:	95be                	add	a1,a1,a5
    80001f9a:	06048513          	addi	a0,s1,96
    80001f9e:	00000097          	auipc	ra,0x0
    80001fa2:	602080e7          	jalr	1538(ra) # 800025a0 <swtch>
    80001fa6:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80001fa8:	2781                	sext.w	a5,a5
    80001faa:	079e                	slli	a5,a5,0x7
    80001fac:	993e                	add	s2,s2,a5
    80001fae:	0b392623          	sw	s3,172(s2)
}
    80001fb2:	70a2                	ld	ra,40(sp)
    80001fb4:	7402                	ld	s0,32(sp)
    80001fb6:	64e2                	ld	s1,24(sp)
    80001fb8:	6942                	ld	s2,16(sp)
    80001fba:	69a2                	ld	s3,8(sp)
    80001fbc:	6145                	addi	sp,sp,48
    80001fbe:	8082                	ret
    panic("sched p->lock");
    80001fc0:	00006517          	auipc	a0,0x6
    80001fc4:	27850513          	addi	a0,a0,632 # 80008238 <digits+0x1f8>
    80001fc8:	ffffe097          	auipc	ra,0xffffe
    80001fcc:	572080e7          	jalr	1394(ra) # 8000053a <panic>
    panic("sched locks");
    80001fd0:	00006517          	auipc	a0,0x6
    80001fd4:	27850513          	addi	a0,a0,632 # 80008248 <digits+0x208>
    80001fd8:	ffffe097          	auipc	ra,0xffffe
    80001fdc:	562080e7          	jalr	1378(ra) # 8000053a <panic>
    panic("sched running");
    80001fe0:	00006517          	auipc	a0,0x6
    80001fe4:	27850513          	addi	a0,a0,632 # 80008258 <digits+0x218>
    80001fe8:	ffffe097          	auipc	ra,0xffffe
    80001fec:	552080e7          	jalr	1362(ra) # 8000053a <panic>
    panic("sched interruptible");
    80001ff0:	00006517          	auipc	a0,0x6
    80001ff4:	27850513          	addi	a0,a0,632 # 80008268 <digits+0x228>
    80001ff8:	ffffe097          	auipc	ra,0xffffe
    80001ffc:	542080e7          	jalr	1346(ra) # 8000053a <panic>

0000000080002000 <yield>:
{
    80002000:	1101                	addi	sp,sp,-32
    80002002:	ec06                	sd	ra,24(sp)
    80002004:	e822                	sd	s0,16(sp)
    80002006:	e426                	sd	s1,8(sp)
    80002008:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000200a:	00000097          	auipc	ra,0x0
    8000200e:	98a080e7          	jalr	-1654(ra) # 80001994 <myproc>
    80002012:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002014:	fffff097          	auipc	ra,0xfffff
    80002018:	bbc080e7          	jalr	-1092(ra) # 80000bd0 <acquire>
  p->state = RUNNABLE;
    8000201c:	478d                	li	a5,3
    8000201e:	cc9c                	sw	a5,24(s1)
  sched();
    80002020:	00000097          	auipc	ra,0x0
    80002024:	f0a080e7          	jalr	-246(ra) # 80001f2a <sched>
  release(&p->lock);
    80002028:	8526                	mv	a0,s1
    8000202a:	fffff097          	auipc	ra,0xfffff
    8000202e:	c5a080e7          	jalr	-934(ra) # 80000c84 <release>
}
    80002032:	60e2                	ld	ra,24(sp)
    80002034:	6442                	ld	s0,16(sp)
    80002036:	64a2                	ld	s1,8(sp)
    80002038:	6105                	addi	sp,sp,32
    8000203a:	8082                	ret

000000008000203c <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    8000203c:	7179                	addi	sp,sp,-48
    8000203e:	f406                	sd	ra,40(sp)
    80002040:	f022                	sd	s0,32(sp)
    80002042:	ec26                	sd	s1,24(sp)
    80002044:	e84a                	sd	s2,16(sp)
    80002046:	e44e                	sd	s3,8(sp)
    80002048:	1800                	addi	s0,sp,48
    8000204a:	89aa                	mv	s3,a0
    8000204c:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000204e:	00000097          	auipc	ra,0x0
    80002052:	946080e7          	jalr	-1722(ra) # 80001994 <myproc>
    80002056:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002058:	fffff097          	auipc	ra,0xfffff
    8000205c:	b78080e7          	jalr	-1160(ra) # 80000bd0 <acquire>
  release(lk);
    80002060:	854a                	mv	a0,s2
    80002062:	fffff097          	auipc	ra,0xfffff
    80002066:	c22080e7          	jalr	-990(ra) # 80000c84 <release>

  // Go to sleep.
  p->chan = chan;
    8000206a:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    8000206e:	4789                	li	a5,2
    80002070:	cc9c                	sw	a5,24(s1)

  sched();
    80002072:	00000097          	auipc	ra,0x0
    80002076:	eb8080e7          	jalr	-328(ra) # 80001f2a <sched>

  // Tidy up.
  p->chan = 0;
    8000207a:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    8000207e:	8526                	mv	a0,s1
    80002080:	fffff097          	auipc	ra,0xfffff
    80002084:	c04080e7          	jalr	-1020(ra) # 80000c84 <release>
  acquire(lk);
    80002088:	854a                	mv	a0,s2
    8000208a:	fffff097          	auipc	ra,0xfffff
    8000208e:	b46080e7          	jalr	-1210(ra) # 80000bd0 <acquire>
}
    80002092:	70a2                	ld	ra,40(sp)
    80002094:	7402                	ld	s0,32(sp)
    80002096:	64e2                	ld	s1,24(sp)
    80002098:	6942                	ld	s2,16(sp)
    8000209a:	69a2                	ld	s3,8(sp)
    8000209c:	6145                	addi	sp,sp,48
    8000209e:	8082                	ret

00000000800020a0 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    800020a0:	7139                	addi	sp,sp,-64
    800020a2:	fc06                	sd	ra,56(sp)
    800020a4:	f822                	sd	s0,48(sp)
    800020a6:	f426                	sd	s1,40(sp)
    800020a8:	f04a                	sd	s2,32(sp)
    800020aa:	ec4e                	sd	s3,24(sp)
    800020ac:	e852                	sd	s4,16(sp)
    800020ae:	e456                	sd	s5,8(sp)
    800020b0:	0080                	addi	s0,sp,64
    800020b2:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    800020b4:	0000f497          	auipc	s1,0xf
    800020b8:	ecc48493          	addi	s1,s1,-308 # 80010f80 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    800020bc:	4989                	li	s3,2
        p->state = RUNNABLE;
    800020be:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    800020c0:	00015917          	auipc	s2,0x15
    800020c4:	8c090913          	addi	s2,s2,-1856 # 80016980 <tickslock>
    800020c8:	a811                	j	800020dc <wakeup+0x3c>
      }
      release(&p->lock);
    800020ca:	8526                	mv	a0,s1
    800020cc:	fffff097          	auipc	ra,0xfffff
    800020d0:	bb8080e7          	jalr	-1096(ra) # 80000c84 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800020d4:	16848493          	addi	s1,s1,360
    800020d8:	03248663          	beq	s1,s2,80002104 <wakeup+0x64>
    if(p != myproc()){
    800020dc:	00000097          	auipc	ra,0x0
    800020e0:	8b8080e7          	jalr	-1864(ra) # 80001994 <myproc>
    800020e4:	fea488e3          	beq	s1,a0,800020d4 <wakeup+0x34>
      acquire(&p->lock);
    800020e8:	8526                	mv	a0,s1
    800020ea:	fffff097          	auipc	ra,0xfffff
    800020ee:	ae6080e7          	jalr	-1306(ra) # 80000bd0 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    800020f2:	4c9c                	lw	a5,24(s1)
    800020f4:	fd379be3          	bne	a5,s3,800020ca <wakeup+0x2a>
    800020f8:	709c                	ld	a5,32(s1)
    800020fa:	fd4798e3          	bne	a5,s4,800020ca <wakeup+0x2a>
        p->state = RUNNABLE;
    800020fe:	0154ac23          	sw	s5,24(s1)
    80002102:	b7e1                	j	800020ca <wakeup+0x2a>
    }
  }
}
    80002104:	70e2                	ld	ra,56(sp)
    80002106:	7442                	ld	s0,48(sp)
    80002108:	74a2                	ld	s1,40(sp)
    8000210a:	7902                	ld	s2,32(sp)
    8000210c:	69e2                	ld	s3,24(sp)
    8000210e:	6a42                	ld	s4,16(sp)
    80002110:	6aa2                	ld	s5,8(sp)
    80002112:	6121                	addi	sp,sp,64
    80002114:	8082                	ret

0000000080002116 <reparent>:
{
    80002116:	7179                	addi	sp,sp,-48
    80002118:	f406                	sd	ra,40(sp)
    8000211a:	f022                	sd	s0,32(sp)
    8000211c:	ec26                	sd	s1,24(sp)
    8000211e:	e84a                	sd	s2,16(sp)
    80002120:	e44e                	sd	s3,8(sp)
    80002122:	e052                	sd	s4,0(sp)
    80002124:	1800                	addi	s0,sp,48
    80002126:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002128:	0000f497          	auipc	s1,0xf
    8000212c:	e5848493          	addi	s1,s1,-424 # 80010f80 <proc>
      pp->parent = initproc;
    80002130:	00006a17          	auipc	s4,0x6
    80002134:	7a8a0a13          	addi	s4,s4,1960 # 800088d8 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002138:	00015997          	auipc	s3,0x15
    8000213c:	84898993          	addi	s3,s3,-1976 # 80016980 <tickslock>
    80002140:	a029                	j	8000214a <reparent+0x34>
    80002142:	16848493          	addi	s1,s1,360
    80002146:	01348d63          	beq	s1,s3,80002160 <reparent+0x4a>
    if(pp->parent == p){
    8000214a:	7c9c                	ld	a5,56(s1)
    8000214c:	ff279be3          	bne	a5,s2,80002142 <reparent+0x2c>
      pp->parent = initproc;
    80002150:	000a3503          	ld	a0,0(s4)
    80002154:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002156:	00000097          	auipc	ra,0x0
    8000215a:	f4a080e7          	jalr	-182(ra) # 800020a0 <wakeup>
    8000215e:	b7d5                	j	80002142 <reparent+0x2c>
}
    80002160:	70a2                	ld	ra,40(sp)
    80002162:	7402                	ld	s0,32(sp)
    80002164:	64e2                	ld	s1,24(sp)
    80002166:	6942                	ld	s2,16(sp)
    80002168:	69a2                	ld	s3,8(sp)
    8000216a:	6a02                	ld	s4,0(sp)
    8000216c:	6145                	addi	sp,sp,48
    8000216e:	8082                	ret

0000000080002170 <exit>:
{
    80002170:	7179                	addi	sp,sp,-48
    80002172:	f406                	sd	ra,40(sp)
    80002174:	f022                	sd	s0,32(sp)
    80002176:	ec26                	sd	s1,24(sp)
    80002178:	e84a                	sd	s2,16(sp)
    8000217a:	e44e                	sd	s3,8(sp)
    8000217c:	e052                	sd	s4,0(sp)
    8000217e:	1800                	addi	s0,sp,48
    80002180:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002182:	00000097          	auipc	ra,0x0
    80002186:	812080e7          	jalr	-2030(ra) # 80001994 <myproc>
    8000218a:	89aa                	mv	s3,a0
  if(p == initproc)
    8000218c:	00006797          	auipc	a5,0x6
    80002190:	74c7b783          	ld	a5,1868(a5) # 800088d8 <initproc>
    80002194:	0d050493          	addi	s1,a0,208
    80002198:	15050913          	addi	s2,a0,336
    8000219c:	02a79363          	bne	a5,a0,800021c2 <exit+0x52>
    panic("init exiting");
    800021a0:	00006517          	auipc	a0,0x6
    800021a4:	0e050513          	addi	a0,a0,224 # 80008280 <digits+0x240>
    800021a8:	ffffe097          	auipc	ra,0xffffe
    800021ac:	392080e7          	jalr	914(ra) # 8000053a <panic>
      fileclose(f);
    800021b0:	00002097          	auipc	ra,0x2
    800021b4:	2ca080e7          	jalr	714(ra) # 8000447a <fileclose>
      p->ofile[fd] = 0;
    800021b8:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800021bc:	04a1                	addi	s1,s1,8
    800021be:	01248563          	beq	s1,s2,800021c8 <exit+0x58>
    if(p->ofile[fd]){
    800021c2:	6088                	ld	a0,0(s1)
    800021c4:	f575                	bnez	a0,800021b0 <exit+0x40>
    800021c6:	bfdd                	j	800021bc <exit+0x4c>
  begin_op();
    800021c8:	00002097          	auipc	ra,0x2
    800021cc:	dee080e7          	jalr	-530(ra) # 80003fb6 <begin_op>
  iput(p->cwd);
    800021d0:	1509b503          	ld	a0,336(s3)
    800021d4:	00001097          	auipc	ra,0x1
    800021d8:	5f6080e7          	jalr	1526(ra) # 800037ca <iput>
  end_op();
    800021dc:	00002097          	auipc	ra,0x2
    800021e0:	e54080e7          	jalr	-428(ra) # 80004030 <end_op>
  p->cwd = 0;
    800021e4:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    800021e8:	0000f497          	auipc	s1,0xf
    800021ec:	98048493          	addi	s1,s1,-1664 # 80010b68 <wait_lock>
    800021f0:	8526                	mv	a0,s1
    800021f2:	fffff097          	auipc	ra,0xfffff
    800021f6:	9de080e7          	jalr	-1570(ra) # 80000bd0 <acquire>
  reparent(p);
    800021fa:	854e                	mv	a0,s3
    800021fc:	00000097          	auipc	ra,0x0
    80002200:	f1a080e7          	jalr	-230(ra) # 80002116 <reparent>
  wakeup(p->parent);
    80002204:	0389b503          	ld	a0,56(s3)
    80002208:	00000097          	auipc	ra,0x0
    8000220c:	e98080e7          	jalr	-360(ra) # 800020a0 <wakeup>
  acquire(&p->lock);
    80002210:	854e                	mv	a0,s3
    80002212:	fffff097          	auipc	ra,0xfffff
    80002216:	9be080e7          	jalr	-1602(ra) # 80000bd0 <acquire>
  p->xstate = status;
    8000221a:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    8000221e:	4795                	li	a5,5
    80002220:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    80002224:	8526                	mv	a0,s1
    80002226:	fffff097          	auipc	ra,0xfffff
    8000222a:	a5e080e7          	jalr	-1442(ra) # 80000c84 <release>
  sched();
    8000222e:	00000097          	auipc	ra,0x0
    80002232:	cfc080e7          	jalr	-772(ra) # 80001f2a <sched>
  panic("zombie exit");
    80002236:	00006517          	auipc	a0,0x6
    8000223a:	05a50513          	addi	a0,a0,90 # 80008290 <digits+0x250>
    8000223e:	ffffe097          	auipc	ra,0xffffe
    80002242:	2fc080e7          	jalr	764(ra) # 8000053a <panic>

0000000080002246 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002246:	7179                	addi	sp,sp,-48
    80002248:	f406                	sd	ra,40(sp)
    8000224a:	f022                	sd	s0,32(sp)
    8000224c:	ec26                	sd	s1,24(sp)
    8000224e:	e84a                	sd	s2,16(sp)
    80002250:	e44e                	sd	s3,8(sp)
    80002252:	1800                	addi	s0,sp,48
    80002254:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002256:	0000f497          	auipc	s1,0xf
    8000225a:	d2a48493          	addi	s1,s1,-726 # 80010f80 <proc>
    8000225e:	00014997          	auipc	s3,0x14
    80002262:	72298993          	addi	s3,s3,1826 # 80016980 <tickslock>
    acquire(&p->lock);
    80002266:	8526                	mv	a0,s1
    80002268:	fffff097          	auipc	ra,0xfffff
    8000226c:	968080e7          	jalr	-1688(ra) # 80000bd0 <acquire>
    if(p->pid == pid){
    80002270:	589c                	lw	a5,48(s1)
    80002272:	01278d63          	beq	a5,s2,8000228c <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002276:	8526                	mv	a0,s1
    80002278:	fffff097          	auipc	ra,0xfffff
    8000227c:	a0c080e7          	jalr	-1524(ra) # 80000c84 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002280:	16848493          	addi	s1,s1,360
    80002284:	ff3491e3          	bne	s1,s3,80002266 <kill+0x20>
  }
  return -1;
    80002288:	557d                	li	a0,-1
    8000228a:	a829                	j	800022a4 <kill+0x5e>
      p->killed = 1;
    8000228c:	4785                	li	a5,1
    8000228e:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    80002290:	4c98                	lw	a4,24(s1)
    80002292:	4789                	li	a5,2
    80002294:	00f70f63          	beq	a4,a5,800022b2 <kill+0x6c>
      release(&p->lock);
    80002298:	8526                	mv	a0,s1
    8000229a:	fffff097          	auipc	ra,0xfffff
    8000229e:	9ea080e7          	jalr	-1558(ra) # 80000c84 <release>
      return 0;
    800022a2:	4501                	li	a0,0
}
    800022a4:	70a2                	ld	ra,40(sp)
    800022a6:	7402                	ld	s0,32(sp)
    800022a8:	64e2                	ld	s1,24(sp)
    800022aa:	6942                	ld	s2,16(sp)
    800022ac:	69a2                	ld	s3,8(sp)
    800022ae:	6145                	addi	sp,sp,48
    800022b0:	8082                	ret
        p->state = RUNNABLE;
    800022b2:	478d                	li	a5,3
    800022b4:	cc9c                	sw	a5,24(s1)
    800022b6:	b7cd                	j	80002298 <kill+0x52>

00000000800022b8 <setkilled>:

void
setkilled(struct proc *p)
{
    800022b8:	1101                	addi	sp,sp,-32
    800022ba:	ec06                	sd	ra,24(sp)
    800022bc:	e822                	sd	s0,16(sp)
    800022be:	e426                	sd	s1,8(sp)
    800022c0:	1000                	addi	s0,sp,32
    800022c2:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800022c4:	fffff097          	auipc	ra,0xfffff
    800022c8:	90c080e7          	jalr	-1780(ra) # 80000bd0 <acquire>
  p->killed = 1;
    800022cc:	4785                	li	a5,1
    800022ce:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    800022d0:	8526                	mv	a0,s1
    800022d2:	fffff097          	auipc	ra,0xfffff
    800022d6:	9b2080e7          	jalr	-1614(ra) # 80000c84 <release>
}
    800022da:	60e2                	ld	ra,24(sp)
    800022dc:	6442                	ld	s0,16(sp)
    800022de:	64a2                	ld	s1,8(sp)
    800022e0:	6105                	addi	sp,sp,32
    800022e2:	8082                	ret

00000000800022e4 <killed>:

int
killed(struct proc *p)
{
    800022e4:	1101                	addi	sp,sp,-32
    800022e6:	ec06                	sd	ra,24(sp)
    800022e8:	e822                	sd	s0,16(sp)
    800022ea:	e426                	sd	s1,8(sp)
    800022ec:	e04a                	sd	s2,0(sp)
    800022ee:	1000                	addi	s0,sp,32
    800022f0:	84aa                	mv	s1,a0
  int k;
  
  acquire(&p->lock);
    800022f2:	fffff097          	auipc	ra,0xfffff
    800022f6:	8de080e7          	jalr	-1826(ra) # 80000bd0 <acquire>
  k = p->killed;
    800022fa:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    800022fe:	8526                	mv	a0,s1
    80002300:	fffff097          	auipc	ra,0xfffff
    80002304:	984080e7          	jalr	-1660(ra) # 80000c84 <release>
  return k;
}
    80002308:	854a                	mv	a0,s2
    8000230a:	60e2                	ld	ra,24(sp)
    8000230c:	6442                	ld	s0,16(sp)
    8000230e:	64a2                	ld	s1,8(sp)
    80002310:	6902                	ld	s2,0(sp)
    80002312:	6105                	addi	sp,sp,32
    80002314:	8082                	ret

0000000080002316 <wait>:
{
    80002316:	715d                	addi	sp,sp,-80
    80002318:	e486                	sd	ra,72(sp)
    8000231a:	e0a2                	sd	s0,64(sp)
    8000231c:	fc26                	sd	s1,56(sp)
    8000231e:	f84a                	sd	s2,48(sp)
    80002320:	f44e                	sd	s3,40(sp)
    80002322:	f052                	sd	s4,32(sp)
    80002324:	ec56                	sd	s5,24(sp)
    80002326:	e85a                	sd	s6,16(sp)
    80002328:	e45e                	sd	s7,8(sp)
    8000232a:	e062                	sd	s8,0(sp)
    8000232c:	0880                	addi	s0,sp,80
    8000232e:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002330:	fffff097          	auipc	ra,0xfffff
    80002334:	664080e7          	jalr	1636(ra) # 80001994 <myproc>
    80002338:	892a                	mv	s2,a0
  acquire(&wait_lock);
    8000233a:	0000f517          	auipc	a0,0xf
    8000233e:	82e50513          	addi	a0,a0,-2002 # 80010b68 <wait_lock>
    80002342:	fffff097          	auipc	ra,0xfffff
    80002346:	88e080e7          	jalr	-1906(ra) # 80000bd0 <acquire>
    havekids = 0;
    8000234a:	4b81                	li	s7,0
        if(pp->state == ZOMBIE){
    8000234c:	4a15                	li	s4,5
        havekids = 1;
    8000234e:	4a85                	li	s5,1
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002350:	00014997          	auipc	s3,0x14
    80002354:	63098993          	addi	s3,s3,1584 # 80016980 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002358:	0000fc17          	auipc	s8,0xf
    8000235c:	810c0c13          	addi	s8,s8,-2032 # 80010b68 <wait_lock>
    80002360:	a0d1                	j	80002424 <wait+0x10e>
          pid = pp->pid;
    80002362:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    80002366:	000b0e63          	beqz	s6,80002382 <wait+0x6c>
    8000236a:	4691                	li	a3,4
    8000236c:	02c48613          	addi	a2,s1,44
    80002370:	85da                	mv	a1,s6
    80002372:	05093503          	ld	a0,80(s2)
    80002376:	fffff097          	auipc	ra,0xfffff
    8000237a:	2de080e7          	jalr	734(ra) # 80001654 <copyout>
    8000237e:	04054163          	bltz	a0,800023c0 <wait+0xaa>
          freeproc(pp);
    80002382:	8526                	mv	a0,s1
    80002384:	fffff097          	auipc	ra,0xfffff
    80002388:	7c2080e7          	jalr	1986(ra) # 80001b46 <freeproc>
          release(&pp->lock);
    8000238c:	8526                	mv	a0,s1
    8000238e:	fffff097          	auipc	ra,0xfffff
    80002392:	8f6080e7          	jalr	-1802(ra) # 80000c84 <release>
          release(&wait_lock);
    80002396:	0000e517          	auipc	a0,0xe
    8000239a:	7d250513          	addi	a0,a0,2002 # 80010b68 <wait_lock>
    8000239e:	fffff097          	auipc	ra,0xfffff
    800023a2:	8e6080e7          	jalr	-1818(ra) # 80000c84 <release>
}
    800023a6:	854e                	mv	a0,s3
    800023a8:	60a6                	ld	ra,72(sp)
    800023aa:	6406                	ld	s0,64(sp)
    800023ac:	74e2                	ld	s1,56(sp)
    800023ae:	7942                	ld	s2,48(sp)
    800023b0:	79a2                	ld	s3,40(sp)
    800023b2:	7a02                	ld	s4,32(sp)
    800023b4:	6ae2                	ld	s5,24(sp)
    800023b6:	6b42                	ld	s6,16(sp)
    800023b8:	6ba2                	ld	s7,8(sp)
    800023ba:	6c02                	ld	s8,0(sp)
    800023bc:	6161                	addi	sp,sp,80
    800023be:	8082                	ret
            release(&pp->lock);
    800023c0:	8526                	mv	a0,s1
    800023c2:	fffff097          	auipc	ra,0xfffff
    800023c6:	8c2080e7          	jalr	-1854(ra) # 80000c84 <release>
            release(&wait_lock);
    800023ca:	0000e517          	auipc	a0,0xe
    800023ce:	79e50513          	addi	a0,a0,1950 # 80010b68 <wait_lock>
    800023d2:	fffff097          	auipc	ra,0xfffff
    800023d6:	8b2080e7          	jalr	-1870(ra) # 80000c84 <release>
            return -1;
    800023da:	59fd                	li	s3,-1
    800023dc:	b7e9                	j	800023a6 <wait+0x90>
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800023de:	16848493          	addi	s1,s1,360
    800023e2:	03348463          	beq	s1,s3,8000240a <wait+0xf4>
      if(pp->parent == p){
    800023e6:	7c9c                	ld	a5,56(s1)
    800023e8:	ff279be3          	bne	a5,s2,800023de <wait+0xc8>
        acquire(&pp->lock);
    800023ec:	8526                	mv	a0,s1
    800023ee:	ffffe097          	auipc	ra,0xffffe
    800023f2:	7e2080e7          	jalr	2018(ra) # 80000bd0 <acquire>
        if(pp->state == ZOMBIE){
    800023f6:	4c9c                	lw	a5,24(s1)
    800023f8:	f74785e3          	beq	a5,s4,80002362 <wait+0x4c>
        release(&pp->lock);
    800023fc:	8526                	mv	a0,s1
    800023fe:	fffff097          	auipc	ra,0xfffff
    80002402:	886080e7          	jalr	-1914(ra) # 80000c84 <release>
        havekids = 1;
    80002406:	8756                	mv	a4,s5
    80002408:	bfd9                	j	800023de <wait+0xc8>
    if(!havekids || killed(p)){
    8000240a:	c31d                	beqz	a4,80002430 <wait+0x11a>
    8000240c:	854a                	mv	a0,s2
    8000240e:	00000097          	auipc	ra,0x0
    80002412:	ed6080e7          	jalr	-298(ra) # 800022e4 <killed>
    80002416:	ed09                	bnez	a0,80002430 <wait+0x11a>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002418:	85e2                	mv	a1,s8
    8000241a:	854a                	mv	a0,s2
    8000241c:	00000097          	auipc	ra,0x0
    80002420:	c20080e7          	jalr	-992(ra) # 8000203c <sleep>
    havekids = 0;
    80002424:	875e                	mv	a4,s7
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002426:	0000f497          	auipc	s1,0xf
    8000242a:	b5a48493          	addi	s1,s1,-1190 # 80010f80 <proc>
    8000242e:	bf65                	j	800023e6 <wait+0xd0>
      release(&wait_lock);
    80002430:	0000e517          	auipc	a0,0xe
    80002434:	73850513          	addi	a0,a0,1848 # 80010b68 <wait_lock>
    80002438:	fffff097          	auipc	ra,0xfffff
    8000243c:	84c080e7          	jalr	-1972(ra) # 80000c84 <release>
      return -1;
    80002440:	59fd                	li	s3,-1
    80002442:	b795                	j	800023a6 <wait+0x90>

0000000080002444 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002444:	7179                	addi	sp,sp,-48
    80002446:	f406                	sd	ra,40(sp)
    80002448:	f022                	sd	s0,32(sp)
    8000244a:	ec26                	sd	s1,24(sp)
    8000244c:	e84a                	sd	s2,16(sp)
    8000244e:	e44e                	sd	s3,8(sp)
    80002450:	e052                	sd	s4,0(sp)
    80002452:	1800                	addi	s0,sp,48
    80002454:	84aa                	mv	s1,a0
    80002456:	892e                	mv	s2,a1
    80002458:	89b2                	mv	s3,a2
    8000245a:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000245c:	fffff097          	auipc	ra,0xfffff
    80002460:	538080e7          	jalr	1336(ra) # 80001994 <myproc>
  if(user_dst){
    80002464:	c08d                	beqz	s1,80002486 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002466:	86d2                	mv	a3,s4
    80002468:	864e                	mv	a2,s3
    8000246a:	85ca                	mv	a1,s2
    8000246c:	6928                	ld	a0,80(a0)
    8000246e:	fffff097          	auipc	ra,0xfffff
    80002472:	1e6080e7          	jalr	486(ra) # 80001654 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002476:	70a2                	ld	ra,40(sp)
    80002478:	7402                	ld	s0,32(sp)
    8000247a:	64e2                	ld	s1,24(sp)
    8000247c:	6942                	ld	s2,16(sp)
    8000247e:	69a2                	ld	s3,8(sp)
    80002480:	6a02                	ld	s4,0(sp)
    80002482:	6145                	addi	sp,sp,48
    80002484:	8082                	ret
    memmove((char *)dst, src, len);
    80002486:	000a061b          	sext.w	a2,s4
    8000248a:	85ce                	mv	a1,s3
    8000248c:	854a                	mv	a0,s2
    8000248e:	fffff097          	auipc	ra,0xfffff
    80002492:	89a080e7          	jalr	-1894(ra) # 80000d28 <memmove>
    return 0;
    80002496:	8526                	mv	a0,s1
    80002498:	bff9                	j	80002476 <either_copyout+0x32>

000000008000249a <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    8000249a:	7179                	addi	sp,sp,-48
    8000249c:	f406                	sd	ra,40(sp)
    8000249e:	f022                	sd	s0,32(sp)
    800024a0:	ec26                	sd	s1,24(sp)
    800024a2:	e84a                	sd	s2,16(sp)
    800024a4:	e44e                	sd	s3,8(sp)
    800024a6:	e052                	sd	s4,0(sp)
    800024a8:	1800                	addi	s0,sp,48
    800024aa:	892a                	mv	s2,a0
    800024ac:	84ae                	mv	s1,a1
    800024ae:	89b2                	mv	s3,a2
    800024b0:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024b2:	fffff097          	auipc	ra,0xfffff
    800024b6:	4e2080e7          	jalr	1250(ra) # 80001994 <myproc>
  if(user_src){
    800024ba:	c08d                	beqz	s1,800024dc <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800024bc:	86d2                	mv	a3,s4
    800024be:	864e                	mv	a2,s3
    800024c0:	85ca                	mv	a1,s2
    800024c2:	6928                	ld	a0,80(a0)
    800024c4:	fffff097          	auipc	ra,0xfffff
    800024c8:	21c080e7          	jalr	540(ra) # 800016e0 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800024cc:	70a2                	ld	ra,40(sp)
    800024ce:	7402                	ld	s0,32(sp)
    800024d0:	64e2                	ld	s1,24(sp)
    800024d2:	6942                	ld	s2,16(sp)
    800024d4:	69a2                	ld	s3,8(sp)
    800024d6:	6a02                	ld	s4,0(sp)
    800024d8:	6145                	addi	sp,sp,48
    800024da:	8082                	ret
    memmove(dst, (char*)src, len);
    800024dc:	000a061b          	sext.w	a2,s4
    800024e0:	85ce                	mv	a1,s3
    800024e2:	854a                	mv	a0,s2
    800024e4:	fffff097          	auipc	ra,0xfffff
    800024e8:	844080e7          	jalr	-1980(ra) # 80000d28 <memmove>
    return 0;
    800024ec:	8526                	mv	a0,s1
    800024ee:	bff9                	j	800024cc <either_copyin+0x32>

00000000800024f0 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800024f0:	715d                	addi	sp,sp,-80
    800024f2:	e486                	sd	ra,72(sp)
    800024f4:	e0a2                	sd	s0,64(sp)
    800024f6:	fc26                	sd	s1,56(sp)
    800024f8:	f84a                	sd	s2,48(sp)
    800024fa:	f44e                	sd	s3,40(sp)
    800024fc:	f052                	sd	s4,32(sp)
    800024fe:	ec56                	sd	s5,24(sp)
    80002500:	e85a                	sd	s6,16(sp)
    80002502:	e45e                	sd	s7,8(sp)
    80002504:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002506:	00006517          	auipc	a0,0x6
    8000250a:	be250513          	addi	a0,a0,-1054 # 800080e8 <digits+0xa8>
    8000250e:	ffffe097          	auipc	ra,0xffffe
    80002512:	076080e7          	jalr	118(ra) # 80000584 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002516:	0000f497          	auipc	s1,0xf
    8000251a:	bc248493          	addi	s1,s1,-1086 # 800110d8 <proc+0x158>
    8000251e:	00014917          	auipc	s2,0x14
    80002522:	5ba90913          	addi	s2,s2,1466 # 80016ad8 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002526:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002528:	00006997          	auipc	s3,0x6
    8000252c:	d7898993          	addi	s3,s3,-648 # 800082a0 <digits+0x260>
    printf("%d %s %s", p->pid, state, p->name);
    80002530:	00006a97          	auipc	s5,0x6
    80002534:	d78a8a93          	addi	s5,s5,-648 # 800082a8 <digits+0x268>
    printf("\n");
    80002538:	00006a17          	auipc	s4,0x6
    8000253c:	bb0a0a13          	addi	s4,s4,-1104 # 800080e8 <digits+0xa8>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002540:	00006b97          	auipc	s7,0x6
    80002544:	da8b8b93          	addi	s7,s7,-600 # 800082e8 <states.0>
    80002548:	a00d                	j	8000256a <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    8000254a:	ed86a583          	lw	a1,-296(a3)
    8000254e:	8556                	mv	a0,s5
    80002550:	ffffe097          	auipc	ra,0xffffe
    80002554:	034080e7          	jalr	52(ra) # 80000584 <printf>
    printf("\n");
    80002558:	8552                	mv	a0,s4
    8000255a:	ffffe097          	auipc	ra,0xffffe
    8000255e:	02a080e7          	jalr	42(ra) # 80000584 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002562:	16848493          	addi	s1,s1,360
    80002566:	03248263          	beq	s1,s2,8000258a <procdump+0x9a>
    if(p->state == UNUSED)
    8000256a:	86a6                	mv	a3,s1
    8000256c:	ec04a783          	lw	a5,-320(s1)
    80002570:	dbed                	beqz	a5,80002562 <procdump+0x72>
      state = "???";
    80002572:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002574:	fcfb6be3          	bltu	s6,a5,8000254a <procdump+0x5a>
    80002578:	02079713          	slli	a4,a5,0x20
    8000257c:	01d75793          	srli	a5,a4,0x1d
    80002580:	97de                	add	a5,a5,s7
    80002582:	6390                	ld	a2,0(a5)
    80002584:	f279                	bnez	a2,8000254a <procdump+0x5a>
      state = "???";
    80002586:	864e                	mv	a2,s3
    80002588:	b7c9                	j	8000254a <procdump+0x5a>
  }
}
    8000258a:	60a6                	ld	ra,72(sp)
    8000258c:	6406                	ld	s0,64(sp)
    8000258e:	74e2                	ld	s1,56(sp)
    80002590:	7942                	ld	s2,48(sp)
    80002592:	79a2                	ld	s3,40(sp)
    80002594:	7a02                	ld	s4,32(sp)
    80002596:	6ae2                	ld	s5,24(sp)
    80002598:	6b42                	ld	s6,16(sp)
    8000259a:	6ba2                	ld	s7,8(sp)
    8000259c:	6161                	addi	sp,sp,80
    8000259e:	8082                	ret

00000000800025a0 <swtch>:
    800025a0:	00153023          	sd	ra,0(a0)
    800025a4:	00253423          	sd	sp,8(a0)
    800025a8:	e900                	sd	s0,16(a0)
    800025aa:	ed04                	sd	s1,24(a0)
    800025ac:	03253023          	sd	s2,32(a0)
    800025b0:	03353423          	sd	s3,40(a0)
    800025b4:	03453823          	sd	s4,48(a0)
    800025b8:	03553c23          	sd	s5,56(a0)
    800025bc:	05653023          	sd	s6,64(a0)
    800025c0:	05753423          	sd	s7,72(a0)
    800025c4:	05853823          	sd	s8,80(a0)
    800025c8:	05953c23          	sd	s9,88(a0)
    800025cc:	07a53023          	sd	s10,96(a0)
    800025d0:	07b53423          	sd	s11,104(a0)
    800025d4:	0005b083          	ld	ra,0(a1)
    800025d8:	0085b103          	ld	sp,8(a1)
    800025dc:	6980                	ld	s0,16(a1)
    800025de:	6d84                	ld	s1,24(a1)
    800025e0:	0205b903          	ld	s2,32(a1)
    800025e4:	0285b983          	ld	s3,40(a1)
    800025e8:	0305ba03          	ld	s4,48(a1)
    800025ec:	0385ba83          	ld	s5,56(a1)
    800025f0:	0405bb03          	ld	s6,64(a1)
    800025f4:	0485bb83          	ld	s7,72(a1)
    800025f8:	0505bc03          	ld	s8,80(a1)
    800025fc:	0585bc83          	ld	s9,88(a1)
    80002600:	0605bd03          	ld	s10,96(a1)
    80002604:	0685bd83          	ld	s11,104(a1)
    80002608:	8082                	ret

000000008000260a <trapinit>:

extern int devintr();

void
trapinit(void)
{
    8000260a:	1141                	addi	sp,sp,-16
    8000260c:	e406                	sd	ra,8(sp)
    8000260e:	e022                	sd	s0,0(sp)
    80002610:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002612:	00006597          	auipc	a1,0x6
    80002616:	d0658593          	addi	a1,a1,-762 # 80008318 <states.0+0x30>
    8000261a:	00014517          	auipc	a0,0x14
    8000261e:	36650513          	addi	a0,a0,870 # 80016980 <tickslock>
    80002622:	ffffe097          	auipc	ra,0xffffe
    80002626:	51e080e7          	jalr	1310(ra) # 80000b40 <initlock>
}
    8000262a:	60a2                	ld	ra,8(sp)
    8000262c:	6402                	ld	s0,0(sp)
    8000262e:	0141                	addi	sp,sp,16
    80002630:	8082                	ret

0000000080002632 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002632:	1141                	addi	sp,sp,-16
    80002634:	e422                	sd	s0,8(sp)
    80002636:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002638:	00003797          	auipc	a5,0x3
    8000263c:	46878793          	addi	a5,a5,1128 # 80005aa0 <kernelvec>
    80002640:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002644:	6422                	ld	s0,8(sp)
    80002646:	0141                	addi	sp,sp,16
    80002648:	8082                	ret

000000008000264a <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    8000264a:	1141                	addi	sp,sp,-16
    8000264c:	e406                	sd	ra,8(sp)
    8000264e:	e022                	sd	s0,0(sp)
    80002650:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002652:	fffff097          	auipc	ra,0xfffff
    80002656:	342080e7          	jalr	834(ra) # 80001994 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000265a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    8000265e:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002660:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002664:	00005697          	auipc	a3,0x5
    80002668:	99c68693          	addi	a3,a3,-1636 # 80007000 <_trampoline>
    8000266c:	00005717          	auipc	a4,0x5
    80002670:	99470713          	addi	a4,a4,-1644 # 80007000 <_trampoline>
    80002674:	8f15                	sub	a4,a4,a3
    80002676:	040007b7          	lui	a5,0x4000
    8000267a:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    8000267c:	07b2                	slli	a5,a5,0xc
    8000267e:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002680:	10571073          	csrw	stvec,a4
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002684:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002686:	18002673          	csrr	a2,satp
    8000268a:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    8000268c:	6d30                	ld	a2,88(a0)
    8000268e:	6138                	ld	a4,64(a0)
    80002690:	6585                	lui	a1,0x1
    80002692:	972e                	add	a4,a4,a1
    80002694:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002696:	6d38                	ld	a4,88(a0)
    80002698:	00000617          	auipc	a2,0x0
    8000269c:	13460613          	addi	a2,a2,308 # 800027cc <usertrap>
    800026a0:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800026a2:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800026a4:	8612                	mv	a2,tp
    800026a6:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800026a8:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800026ac:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800026b0:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800026b4:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800026b8:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800026ba:	6f18                	ld	a4,24(a4)
    800026bc:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800026c0:	6928                	ld	a0,80(a0)
    800026c2:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    800026c4:	00005717          	auipc	a4,0x5
    800026c8:	9d870713          	addi	a4,a4,-1576 # 8000709c <userret>
    800026cc:	8f15                	sub	a4,a4,a3
    800026ce:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    800026d0:	577d                	li	a4,-1
    800026d2:	177e                	slli	a4,a4,0x3f
    800026d4:	8d59                	or	a0,a0,a4
    800026d6:	9782                	jalr	a5
}
    800026d8:	60a2                	ld	ra,8(sp)
    800026da:	6402                	ld	s0,0(sp)
    800026dc:	0141                	addi	sp,sp,16
    800026de:	8082                	ret

00000000800026e0 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800026e0:	1101                	addi	sp,sp,-32
    800026e2:	ec06                	sd	ra,24(sp)
    800026e4:	e822                	sd	s0,16(sp)
    800026e6:	e426                	sd	s1,8(sp)
    800026e8:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800026ea:	00014497          	auipc	s1,0x14
    800026ee:	29648493          	addi	s1,s1,662 # 80016980 <tickslock>
    800026f2:	8526                	mv	a0,s1
    800026f4:	ffffe097          	auipc	ra,0xffffe
    800026f8:	4dc080e7          	jalr	1244(ra) # 80000bd0 <acquire>
  ticks++;
    800026fc:	00006517          	auipc	a0,0x6
    80002700:	1e450513          	addi	a0,a0,484 # 800088e0 <ticks>
    80002704:	411c                	lw	a5,0(a0)
    80002706:	2785                	addiw	a5,a5,1
    80002708:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    8000270a:	00000097          	auipc	ra,0x0
    8000270e:	996080e7          	jalr	-1642(ra) # 800020a0 <wakeup>
  release(&tickslock);
    80002712:	8526                	mv	a0,s1
    80002714:	ffffe097          	auipc	ra,0xffffe
    80002718:	570080e7          	jalr	1392(ra) # 80000c84 <release>
}
    8000271c:	60e2                	ld	ra,24(sp)
    8000271e:	6442                	ld	s0,16(sp)
    80002720:	64a2                	ld	s1,8(sp)
    80002722:	6105                	addi	sp,sp,32
    80002724:	8082                	ret

0000000080002726 <devintr>:
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002726:	142027f3          	csrr	a5,scause
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    8000272a:	4501                	li	a0,0
  if((scause & 0x8000000000000000L) &&
    8000272c:	0807df63          	bgez	a5,800027ca <devintr+0xa4>
{
    80002730:	1101                	addi	sp,sp,-32
    80002732:	ec06                	sd	ra,24(sp)
    80002734:	e822                	sd	s0,16(sp)
    80002736:	e426                	sd	s1,8(sp)
    80002738:	1000                	addi	s0,sp,32
     (scause & 0xff) == 9){
    8000273a:	0ff7f713          	zext.b	a4,a5
  if((scause & 0x8000000000000000L) &&
    8000273e:	46a5                	li	a3,9
    80002740:	00d70d63          	beq	a4,a3,8000275a <devintr+0x34>
  } else if(scause == 0x8000000000000001L){
    80002744:	577d                	li	a4,-1
    80002746:	177e                	slli	a4,a4,0x3f
    80002748:	0705                	addi	a4,a4,1
    return 0;
    8000274a:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    8000274c:	04e78e63          	beq	a5,a4,800027a8 <devintr+0x82>
  }
}
    80002750:	60e2                	ld	ra,24(sp)
    80002752:	6442                	ld	s0,16(sp)
    80002754:	64a2                	ld	s1,8(sp)
    80002756:	6105                	addi	sp,sp,32
    80002758:	8082                	ret
    int irq = plic_claim();
    8000275a:	00003097          	auipc	ra,0x3
    8000275e:	44e080e7          	jalr	1102(ra) # 80005ba8 <plic_claim>
    80002762:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002764:	47a9                	li	a5,10
    80002766:	02f50763          	beq	a0,a5,80002794 <devintr+0x6e>
    } else if(irq == VIRTIO0_IRQ){
    8000276a:	4785                	li	a5,1
    8000276c:	02f50963          	beq	a0,a5,8000279e <devintr+0x78>
    return 1;
    80002770:	4505                	li	a0,1
    } else if(irq){
    80002772:	dcf9                	beqz	s1,80002750 <devintr+0x2a>
      printf("unexpected interrupt irq=%d\n", irq);
    80002774:	85a6                	mv	a1,s1
    80002776:	00006517          	auipc	a0,0x6
    8000277a:	baa50513          	addi	a0,a0,-1110 # 80008320 <states.0+0x38>
    8000277e:	ffffe097          	auipc	ra,0xffffe
    80002782:	e06080e7          	jalr	-506(ra) # 80000584 <printf>
      plic_complete(irq);
    80002786:	8526                	mv	a0,s1
    80002788:	00003097          	auipc	ra,0x3
    8000278c:	444080e7          	jalr	1092(ra) # 80005bcc <plic_complete>
    return 1;
    80002790:	4505                	li	a0,1
    80002792:	bf7d                	j	80002750 <devintr+0x2a>
      uartintr();
    80002794:	ffffe097          	auipc	ra,0xffffe
    80002798:	1fe080e7          	jalr	510(ra) # 80000992 <uartintr>
    if(irq)
    8000279c:	b7ed                	j	80002786 <devintr+0x60>
      virtio_disk_intr();
    8000279e:	00004097          	auipc	ra,0x4
    800027a2:	8f4080e7          	jalr	-1804(ra) # 80006092 <virtio_disk_intr>
    if(irq)
    800027a6:	b7c5                	j	80002786 <devintr+0x60>
    if(cpuid() == 0){
    800027a8:	fffff097          	auipc	ra,0xfffff
    800027ac:	1c0080e7          	jalr	448(ra) # 80001968 <cpuid>
    800027b0:	c901                	beqz	a0,800027c0 <devintr+0x9a>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800027b2:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800027b6:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800027b8:	14479073          	csrw	sip,a5
    return 2;
    800027bc:	4509                	li	a0,2
    800027be:	bf49                	j	80002750 <devintr+0x2a>
      clockintr();
    800027c0:	00000097          	auipc	ra,0x0
    800027c4:	f20080e7          	jalr	-224(ra) # 800026e0 <clockintr>
    800027c8:	b7ed                	j	800027b2 <devintr+0x8c>
}
    800027ca:	8082                	ret

00000000800027cc <usertrap>:
{
    800027cc:	1101                	addi	sp,sp,-32
    800027ce:	ec06                	sd	ra,24(sp)
    800027d0:	e822                	sd	s0,16(sp)
    800027d2:	e426                	sd	s1,8(sp)
    800027d4:	e04a                	sd	s2,0(sp)
    800027d6:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800027d8:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    800027dc:	1007f793          	andi	a5,a5,256
    800027e0:	e3b1                	bnez	a5,80002824 <usertrap+0x58>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800027e2:	00003797          	auipc	a5,0x3
    800027e6:	2be78793          	addi	a5,a5,702 # 80005aa0 <kernelvec>
    800027ea:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800027ee:	fffff097          	auipc	ra,0xfffff
    800027f2:	1a6080e7          	jalr	422(ra) # 80001994 <myproc>
    800027f6:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800027f8:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800027fa:	14102773          	csrr	a4,sepc
    800027fe:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002800:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002804:	47a1                	li	a5,8
    80002806:	02f70763          	beq	a4,a5,80002834 <usertrap+0x68>
  } else if((which_dev = devintr()) != 0){
    8000280a:	00000097          	auipc	ra,0x0
    8000280e:	f1c080e7          	jalr	-228(ra) # 80002726 <devintr>
    80002812:	892a                	mv	s2,a0
    80002814:	c151                	beqz	a0,80002898 <usertrap+0xcc>
  if(killed(p))
    80002816:	8526                	mv	a0,s1
    80002818:	00000097          	auipc	ra,0x0
    8000281c:	acc080e7          	jalr	-1332(ra) # 800022e4 <killed>
    80002820:	c929                	beqz	a0,80002872 <usertrap+0xa6>
    80002822:	a099                	j	80002868 <usertrap+0x9c>
    panic("usertrap: not from user mode");
    80002824:	00006517          	auipc	a0,0x6
    80002828:	b1c50513          	addi	a0,a0,-1252 # 80008340 <states.0+0x58>
    8000282c:	ffffe097          	auipc	ra,0xffffe
    80002830:	d0e080e7          	jalr	-754(ra) # 8000053a <panic>
    if(killed(p))
    80002834:	00000097          	auipc	ra,0x0
    80002838:	ab0080e7          	jalr	-1360(ra) # 800022e4 <killed>
    8000283c:	e921                	bnez	a0,8000288c <usertrap+0xc0>
    p->trapframe->epc += 4;
    8000283e:	6cb8                	ld	a4,88(s1)
    80002840:	6f1c                	ld	a5,24(a4)
    80002842:	0791                	addi	a5,a5,4
    80002844:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002846:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000284a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000284e:	10079073          	csrw	sstatus,a5
    syscall();
    80002852:	00000097          	auipc	ra,0x0
    80002856:	2d4080e7          	jalr	724(ra) # 80002b26 <syscall>
  if(killed(p))
    8000285a:	8526                	mv	a0,s1
    8000285c:	00000097          	auipc	ra,0x0
    80002860:	a88080e7          	jalr	-1400(ra) # 800022e4 <killed>
    80002864:	c911                	beqz	a0,80002878 <usertrap+0xac>
    80002866:	4901                	li	s2,0
    exit(-1);
    80002868:	557d                	li	a0,-1
    8000286a:	00000097          	auipc	ra,0x0
    8000286e:	906080e7          	jalr	-1786(ra) # 80002170 <exit>
  if(which_dev == 2)
    80002872:	4789                	li	a5,2
    80002874:	04f90f63          	beq	s2,a5,800028d2 <usertrap+0x106>
  usertrapret();
    80002878:	00000097          	auipc	ra,0x0
    8000287c:	dd2080e7          	jalr	-558(ra) # 8000264a <usertrapret>
}
    80002880:	60e2                	ld	ra,24(sp)
    80002882:	6442                	ld	s0,16(sp)
    80002884:	64a2                	ld	s1,8(sp)
    80002886:	6902                	ld	s2,0(sp)
    80002888:	6105                	addi	sp,sp,32
    8000288a:	8082                	ret
      exit(-1);
    8000288c:	557d                	li	a0,-1
    8000288e:	00000097          	auipc	ra,0x0
    80002892:	8e2080e7          	jalr	-1822(ra) # 80002170 <exit>
    80002896:	b765                	j	8000283e <usertrap+0x72>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002898:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    8000289c:	5890                	lw	a2,48(s1)
    8000289e:	00006517          	auipc	a0,0x6
    800028a2:	ac250513          	addi	a0,a0,-1342 # 80008360 <states.0+0x78>
    800028a6:	ffffe097          	auipc	ra,0xffffe
    800028aa:	cde080e7          	jalr	-802(ra) # 80000584 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028ae:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800028b2:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    800028b6:	00006517          	auipc	a0,0x6
    800028ba:	ada50513          	addi	a0,a0,-1318 # 80008390 <states.0+0xa8>
    800028be:	ffffe097          	auipc	ra,0xffffe
    800028c2:	cc6080e7          	jalr	-826(ra) # 80000584 <printf>
    setkilled(p);
    800028c6:	8526                	mv	a0,s1
    800028c8:	00000097          	auipc	ra,0x0
    800028cc:	9f0080e7          	jalr	-1552(ra) # 800022b8 <setkilled>
    800028d0:	b769                	j	8000285a <usertrap+0x8e>
    yield();
    800028d2:	fffff097          	auipc	ra,0xfffff
    800028d6:	72e080e7          	jalr	1838(ra) # 80002000 <yield>
    800028da:	bf79                	j	80002878 <usertrap+0xac>

00000000800028dc <kerneltrap>:
{
    800028dc:	7179                	addi	sp,sp,-48
    800028de:	f406                	sd	ra,40(sp)
    800028e0:	f022                	sd	s0,32(sp)
    800028e2:	ec26                	sd	s1,24(sp)
    800028e4:	e84a                	sd	s2,16(sp)
    800028e6:	e44e                	sd	s3,8(sp)
    800028e8:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028ea:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028ee:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028f2:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    800028f6:	1004f793          	andi	a5,s1,256
    800028fa:	cb85                	beqz	a5,8000292a <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028fc:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002900:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002902:	ef85                	bnez	a5,8000293a <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002904:	00000097          	auipc	ra,0x0
    80002908:	e22080e7          	jalr	-478(ra) # 80002726 <devintr>
    8000290c:	cd1d                	beqz	a0,8000294a <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    8000290e:	4789                	li	a5,2
    80002910:	06f50a63          	beq	a0,a5,80002984 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002914:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002918:	10049073          	csrw	sstatus,s1
}
    8000291c:	70a2                	ld	ra,40(sp)
    8000291e:	7402                	ld	s0,32(sp)
    80002920:	64e2                	ld	s1,24(sp)
    80002922:	6942                	ld	s2,16(sp)
    80002924:	69a2                	ld	s3,8(sp)
    80002926:	6145                	addi	sp,sp,48
    80002928:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    8000292a:	00006517          	auipc	a0,0x6
    8000292e:	a8650513          	addi	a0,a0,-1402 # 800083b0 <states.0+0xc8>
    80002932:	ffffe097          	auipc	ra,0xffffe
    80002936:	c08080e7          	jalr	-1016(ra) # 8000053a <panic>
    panic("kerneltrap: interrupts enabled");
    8000293a:	00006517          	auipc	a0,0x6
    8000293e:	a9e50513          	addi	a0,a0,-1378 # 800083d8 <states.0+0xf0>
    80002942:	ffffe097          	auipc	ra,0xffffe
    80002946:	bf8080e7          	jalr	-1032(ra) # 8000053a <panic>
    printf("scause %p\n", scause);
    8000294a:	85ce                	mv	a1,s3
    8000294c:	00006517          	auipc	a0,0x6
    80002950:	aac50513          	addi	a0,a0,-1364 # 800083f8 <states.0+0x110>
    80002954:	ffffe097          	auipc	ra,0xffffe
    80002958:	c30080e7          	jalr	-976(ra) # 80000584 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000295c:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002960:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002964:	00006517          	auipc	a0,0x6
    80002968:	aa450513          	addi	a0,a0,-1372 # 80008408 <states.0+0x120>
    8000296c:	ffffe097          	auipc	ra,0xffffe
    80002970:	c18080e7          	jalr	-1000(ra) # 80000584 <printf>
    panic("kerneltrap");
    80002974:	00006517          	auipc	a0,0x6
    80002978:	aac50513          	addi	a0,a0,-1364 # 80008420 <states.0+0x138>
    8000297c:	ffffe097          	auipc	ra,0xffffe
    80002980:	bbe080e7          	jalr	-1090(ra) # 8000053a <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002984:	fffff097          	auipc	ra,0xfffff
    80002988:	010080e7          	jalr	16(ra) # 80001994 <myproc>
    8000298c:	d541                	beqz	a0,80002914 <kerneltrap+0x38>
    8000298e:	fffff097          	auipc	ra,0xfffff
    80002992:	006080e7          	jalr	6(ra) # 80001994 <myproc>
    80002996:	4d18                	lw	a4,24(a0)
    80002998:	4791                	li	a5,4
    8000299a:	f6f71de3          	bne	a4,a5,80002914 <kerneltrap+0x38>
    yield();
    8000299e:	fffff097          	auipc	ra,0xfffff
    800029a2:	662080e7          	jalr	1634(ra) # 80002000 <yield>
    800029a6:	b7bd                	j	80002914 <kerneltrap+0x38>

00000000800029a8 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    800029a8:	1101                	addi	sp,sp,-32
    800029aa:	ec06                	sd	ra,24(sp)
    800029ac:	e822                	sd	s0,16(sp)
    800029ae:	e426                	sd	s1,8(sp)
    800029b0:	1000                	addi	s0,sp,32
    800029b2:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    800029b4:	fffff097          	auipc	ra,0xfffff
    800029b8:	fe0080e7          	jalr	-32(ra) # 80001994 <myproc>
  switch (n) {
    800029bc:	4795                	li	a5,5
    800029be:	0497e163          	bltu	a5,s1,80002a00 <argraw+0x58>
    800029c2:	048a                	slli	s1,s1,0x2
    800029c4:	00006717          	auipc	a4,0x6
    800029c8:	a9470713          	addi	a4,a4,-1388 # 80008458 <states.0+0x170>
    800029cc:	94ba                	add	s1,s1,a4
    800029ce:	409c                	lw	a5,0(s1)
    800029d0:	97ba                	add	a5,a5,a4
    800029d2:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    800029d4:	6d3c                	ld	a5,88(a0)
    800029d6:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    800029d8:	60e2                	ld	ra,24(sp)
    800029da:	6442                	ld	s0,16(sp)
    800029dc:	64a2                	ld	s1,8(sp)
    800029de:	6105                	addi	sp,sp,32
    800029e0:	8082                	ret
    return p->trapframe->a1;
    800029e2:	6d3c                	ld	a5,88(a0)
    800029e4:	7fa8                	ld	a0,120(a5)
    800029e6:	bfcd                	j	800029d8 <argraw+0x30>
    return p->trapframe->a2;
    800029e8:	6d3c                	ld	a5,88(a0)
    800029ea:	63c8                	ld	a0,128(a5)
    800029ec:	b7f5                	j	800029d8 <argraw+0x30>
    return p->trapframe->a3;
    800029ee:	6d3c                	ld	a5,88(a0)
    800029f0:	67c8                	ld	a0,136(a5)
    800029f2:	b7dd                	j	800029d8 <argraw+0x30>
    return p->trapframe->a4;
    800029f4:	6d3c                	ld	a5,88(a0)
    800029f6:	6bc8                	ld	a0,144(a5)
    800029f8:	b7c5                	j	800029d8 <argraw+0x30>
    return p->trapframe->a5;
    800029fa:	6d3c                	ld	a5,88(a0)
    800029fc:	6fc8                	ld	a0,152(a5)
    800029fe:	bfe9                	j	800029d8 <argraw+0x30>
  panic("argraw");
    80002a00:	00006517          	auipc	a0,0x6
    80002a04:	a3050513          	addi	a0,a0,-1488 # 80008430 <states.0+0x148>
    80002a08:	ffffe097          	auipc	ra,0xffffe
    80002a0c:	b32080e7          	jalr	-1230(ra) # 8000053a <panic>

0000000080002a10 <fetchaddr>:
{
    80002a10:	1101                	addi	sp,sp,-32
    80002a12:	ec06                	sd	ra,24(sp)
    80002a14:	e822                	sd	s0,16(sp)
    80002a16:	e426                	sd	s1,8(sp)
    80002a18:	e04a                	sd	s2,0(sp)
    80002a1a:	1000                	addi	s0,sp,32
    80002a1c:	84aa                	mv	s1,a0
    80002a1e:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002a20:	fffff097          	auipc	ra,0xfffff
    80002a24:	f74080e7          	jalr	-140(ra) # 80001994 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002a28:	653c                	ld	a5,72(a0)
    80002a2a:	02f4f863          	bgeu	s1,a5,80002a5a <fetchaddr+0x4a>
    80002a2e:	00848713          	addi	a4,s1,8
    80002a32:	02e7e663          	bltu	a5,a4,80002a5e <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002a36:	46a1                	li	a3,8
    80002a38:	8626                	mv	a2,s1
    80002a3a:	85ca                	mv	a1,s2
    80002a3c:	6928                	ld	a0,80(a0)
    80002a3e:	fffff097          	auipc	ra,0xfffff
    80002a42:	ca2080e7          	jalr	-862(ra) # 800016e0 <copyin>
    80002a46:	00a03533          	snez	a0,a0
    80002a4a:	40a00533          	neg	a0,a0
}
    80002a4e:	60e2                	ld	ra,24(sp)
    80002a50:	6442                	ld	s0,16(sp)
    80002a52:	64a2                	ld	s1,8(sp)
    80002a54:	6902                	ld	s2,0(sp)
    80002a56:	6105                	addi	sp,sp,32
    80002a58:	8082                	ret
    return -1;
    80002a5a:	557d                	li	a0,-1
    80002a5c:	bfcd                	j	80002a4e <fetchaddr+0x3e>
    80002a5e:	557d                	li	a0,-1
    80002a60:	b7fd                	j	80002a4e <fetchaddr+0x3e>

0000000080002a62 <fetchstr>:
{
    80002a62:	7179                	addi	sp,sp,-48
    80002a64:	f406                	sd	ra,40(sp)
    80002a66:	f022                	sd	s0,32(sp)
    80002a68:	ec26                	sd	s1,24(sp)
    80002a6a:	e84a                	sd	s2,16(sp)
    80002a6c:	e44e                	sd	s3,8(sp)
    80002a6e:	1800                	addi	s0,sp,48
    80002a70:	892a                	mv	s2,a0
    80002a72:	84ae                	mv	s1,a1
    80002a74:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002a76:	fffff097          	auipc	ra,0xfffff
    80002a7a:	f1e080e7          	jalr	-226(ra) # 80001994 <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002a7e:	86ce                	mv	a3,s3
    80002a80:	864a                	mv	a2,s2
    80002a82:	85a6                	mv	a1,s1
    80002a84:	6928                	ld	a0,80(a0)
    80002a86:	fffff097          	auipc	ra,0xfffff
    80002a8a:	ce8080e7          	jalr	-792(ra) # 8000176e <copyinstr>
    80002a8e:	00054e63          	bltz	a0,80002aaa <fetchstr+0x48>
  return strlen(buf);
    80002a92:	8526                	mv	a0,s1
    80002a94:	ffffe097          	auipc	ra,0xffffe
    80002a98:	3b2080e7          	jalr	946(ra) # 80000e46 <strlen>
}
    80002a9c:	70a2                	ld	ra,40(sp)
    80002a9e:	7402                	ld	s0,32(sp)
    80002aa0:	64e2                	ld	s1,24(sp)
    80002aa2:	6942                	ld	s2,16(sp)
    80002aa4:	69a2                	ld	s3,8(sp)
    80002aa6:	6145                	addi	sp,sp,48
    80002aa8:	8082                	ret
    return -1;
    80002aaa:	557d                	li	a0,-1
    80002aac:	bfc5                	j	80002a9c <fetchstr+0x3a>

0000000080002aae <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80002aae:	1101                	addi	sp,sp,-32
    80002ab0:	ec06                	sd	ra,24(sp)
    80002ab2:	e822                	sd	s0,16(sp)
    80002ab4:	e426                	sd	s1,8(sp)
    80002ab6:	1000                	addi	s0,sp,32
    80002ab8:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002aba:	00000097          	auipc	ra,0x0
    80002abe:	eee080e7          	jalr	-274(ra) # 800029a8 <argraw>
    80002ac2:	c088                	sw	a0,0(s1)
}
    80002ac4:	60e2                	ld	ra,24(sp)
    80002ac6:	6442                	ld	s0,16(sp)
    80002ac8:	64a2                	ld	s1,8(sp)
    80002aca:	6105                	addi	sp,sp,32
    80002acc:	8082                	ret

0000000080002ace <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80002ace:	1101                	addi	sp,sp,-32
    80002ad0:	ec06                	sd	ra,24(sp)
    80002ad2:	e822                	sd	s0,16(sp)
    80002ad4:	e426                	sd	s1,8(sp)
    80002ad6:	1000                	addi	s0,sp,32
    80002ad8:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002ada:	00000097          	auipc	ra,0x0
    80002ade:	ece080e7          	jalr	-306(ra) # 800029a8 <argraw>
    80002ae2:	e088                	sd	a0,0(s1)
}
    80002ae4:	60e2                	ld	ra,24(sp)
    80002ae6:	6442                	ld	s0,16(sp)
    80002ae8:	64a2                	ld	s1,8(sp)
    80002aea:	6105                	addi	sp,sp,32
    80002aec:	8082                	ret

0000000080002aee <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002aee:	7179                	addi	sp,sp,-48
    80002af0:	f406                	sd	ra,40(sp)
    80002af2:	f022                	sd	s0,32(sp)
    80002af4:	ec26                	sd	s1,24(sp)
    80002af6:	e84a                	sd	s2,16(sp)
    80002af8:	1800                	addi	s0,sp,48
    80002afa:	84ae                	mv	s1,a1
    80002afc:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002afe:	fd840593          	addi	a1,s0,-40
    80002b02:	00000097          	auipc	ra,0x0
    80002b06:	fcc080e7          	jalr	-52(ra) # 80002ace <argaddr>
  return fetchstr(addr, buf, max);
    80002b0a:	864a                	mv	a2,s2
    80002b0c:	85a6                	mv	a1,s1
    80002b0e:	fd843503          	ld	a0,-40(s0)
    80002b12:	00000097          	auipc	ra,0x0
    80002b16:	f50080e7          	jalr	-176(ra) # 80002a62 <fetchstr>
}
    80002b1a:	70a2                	ld	ra,40(sp)
    80002b1c:	7402                	ld	s0,32(sp)
    80002b1e:	64e2                	ld	s1,24(sp)
    80002b20:	6942                	ld	s2,16(sp)
    80002b22:	6145                	addi	sp,sp,48
    80002b24:	8082                	ret

0000000080002b26 <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    80002b26:	1101                	addi	sp,sp,-32
    80002b28:	ec06                	sd	ra,24(sp)
    80002b2a:	e822                	sd	s0,16(sp)
    80002b2c:	e426                	sd	s1,8(sp)
    80002b2e:	e04a                	sd	s2,0(sp)
    80002b30:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002b32:	fffff097          	auipc	ra,0xfffff
    80002b36:	e62080e7          	jalr	-414(ra) # 80001994 <myproc>
    80002b3a:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002b3c:	05853903          	ld	s2,88(a0)
    80002b40:	0a893783          	ld	a5,168(s2)
    80002b44:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002b48:	37fd                	addiw	a5,a5,-1
    80002b4a:	4751                	li	a4,20
    80002b4c:	00f76f63          	bltu	a4,a5,80002b6a <syscall+0x44>
    80002b50:	00369713          	slli	a4,a3,0x3
    80002b54:	00006797          	auipc	a5,0x6
    80002b58:	91c78793          	addi	a5,a5,-1764 # 80008470 <syscalls>
    80002b5c:	97ba                	add	a5,a5,a4
    80002b5e:	639c                	ld	a5,0(a5)
    80002b60:	c789                	beqz	a5,80002b6a <syscall+0x44>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80002b62:	9782                	jalr	a5
    80002b64:	06a93823          	sd	a0,112(s2)
    80002b68:	a839                	j	80002b86 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002b6a:	15848613          	addi	a2,s1,344
    80002b6e:	588c                	lw	a1,48(s1)
    80002b70:	00006517          	auipc	a0,0x6
    80002b74:	8c850513          	addi	a0,a0,-1848 # 80008438 <states.0+0x150>
    80002b78:	ffffe097          	auipc	ra,0xffffe
    80002b7c:	a0c080e7          	jalr	-1524(ra) # 80000584 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002b80:	6cbc                	ld	a5,88(s1)
    80002b82:	577d                	li	a4,-1
    80002b84:	fbb8                	sd	a4,112(a5)
  }
}
    80002b86:	60e2                	ld	ra,24(sp)
    80002b88:	6442                	ld	s0,16(sp)
    80002b8a:	64a2                	ld	s1,8(sp)
    80002b8c:	6902                	ld	s2,0(sp)
    80002b8e:	6105                	addi	sp,sp,32
    80002b90:	8082                	ret

0000000080002b92 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002b92:	1101                	addi	sp,sp,-32
    80002b94:	ec06                	sd	ra,24(sp)
    80002b96:	e822                	sd	s0,16(sp)
    80002b98:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002b9a:	fec40593          	addi	a1,s0,-20
    80002b9e:	4501                	li	a0,0
    80002ba0:	00000097          	auipc	ra,0x0
    80002ba4:	f0e080e7          	jalr	-242(ra) # 80002aae <argint>
  exit(n);
    80002ba8:	fec42503          	lw	a0,-20(s0)
    80002bac:	fffff097          	auipc	ra,0xfffff
    80002bb0:	5c4080e7          	jalr	1476(ra) # 80002170 <exit>
  return 0;  // not reached
}
    80002bb4:	4501                	li	a0,0
    80002bb6:	60e2                	ld	ra,24(sp)
    80002bb8:	6442                	ld	s0,16(sp)
    80002bba:	6105                	addi	sp,sp,32
    80002bbc:	8082                	ret

0000000080002bbe <sys_getpid>:

uint64
sys_getpid(void)
{
    80002bbe:	1141                	addi	sp,sp,-16
    80002bc0:	e406                	sd	ra,8(sp)
    80002bc2:	e022                	sd	s0,0(sp)
    80002bc4:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002bc6:	fffff097          	auipc	ra,0xfffff
    80002bca:	dce080e7          	jalr	-562(ra) # 80001994 <myproc>
}
    80002bce:	5908                	lw	a0,48(a0)
    80002bd0:	60a2                	ld	ra,8(sp)
    80002bd2:	6402                	ld	s0,0(sp)
    80002bd4:	0141                	addi	sp,sp,16
    80002bd6:	8082                	ret

0000000080002bd8 <sys_fork>:

uint64
sys_fork(void)
{
    80002bd8:	1141                	addi	sp,sp,-16
    80002bda:	e406                	sd	ra,8(sp)
    80002bdc:	e022                	sd	s0,0(sp)
    80002bde:	0800                	addi	s0,sp,16
  return fork();
    80002be0:	fffff097          	auipc	ra,0xfffff
    80002be4:	16a080e7          	jalr	362(ra) # 80001d4a <fork>
}
    80002be8:	60a2                	ld	ra,8(sp)
    80002bea:	6402                	ld	s0,0(sp)
    80002bec:	0141                	addi	sp,sp,16
    80002bee:	8082                	ret

0000000080002bf0 <sys_wait>:

uint64
sys_wait(void)
{
    80002bf0:	1101                	addi	sp,sp,-32
    80002bf2:	ec06                	sd	ra,24(sp)
    80002bf4:	e822                	sd	s0,16(sp)
    80002bf6:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80002bf8:	fe840593          	addi	a1,s0,-24
    80002bfc:	4501                	li	a0,0
    80002bfe:	00000097          	auipc	ra,0x0
    80002c02:	ed0080e7          	jalr	-304(ra) # 80002ace <argaddr>
  return wait(p);
    80002c06:	fe843503          	ld	a0,-24(s0)
    80002c0a:	fffff097          	auipc	ra,0xfffff
    80002c0e:	70c080e7          	jalr	1804(ra) # 80002316 <wait>
}
    80002c12:	60e2                	ld	ra,24(sp)
    80002c14:	6442                	ld	s0,16(sp)
    80002c16:	6105                	addi	sp,sp,32
    80002c18:	8082                	ret

0000000080002c1a <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002c1a:	7179                	addi	sp,sp,-48
    80002c1c:	f406                	sd	ra,40(sp)
    80002c1e:	f022                	sd	s0,32(sp)
    80002c20:	ec26                	sd	s1,24(sp)
    80002c22:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80002c24:	fdc40593          	addi	a1,s0,-36
    80002c28:	4501                	li	a0,0
    80002c2a:	00000097          	auipc	ra,0x0
    80002c2e:	e84080e7          	jalr	-380(ra) # 80002aae <argint>
  addr = myproc()->sz;
    80002c32:	fffff097          	auipc	ra,0xfffff
    80002c36:	d62080e7          	jalr	-670(ra) # 80001994 <myproc>
    80002c3a:	6524                	ld	s1,72(a0)
  if(growproc(n) < 0)
    80002c3c:	fdc42503          	lw	a0,-36(s0)
    80002c40:	fffff097          	auipc	ra,0xfffff
    80002c44:	0ae080e7          	jalr	174(ra) # 80001cee <growproc>
    80002c48:	00054863          	bltz	a0,80002c58 <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80002c4c:	8526                	mv	a0,s1
    80002c4e:	70a2                	ld	ra,40(sp)
    80002c50:	7402                	ld	s0,32(sp)
    80002c52:	64e2                	ld	s1,24(sp)
    80002c54:	6145                	addi	sp,sp,48
    80002c56:	8082                	ret
    return -1;
    80002c58:	54fd                	li	s1,-1
    80002c5a:	bfcd                	j	80002c4c <sys_sbrk+0x32>

0000000080002c5c <sys_sleep>:

uint64
sys_sleep(void)
{
    80002c5c:	7139                	addi	sp,sp,-64
    80002c5e:	fc06                	sd	ra,56(sp)
    80002c60:	f822                	sd	s0,48(sp)
    80002c62:	f426                	sd	s1,40(sp)
    80002c64:	f04a                	sd	s2,32(sp)
    80002c66:	ec4e                	sd	s3,24(sp)
    80002c68:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80002c6a:	fcc40593          	addi	a1,s0,-52
    80002c6e:	4501                	li	a0,0
    80002c70:	00000097          	auipc	ra,0x0
    80002c74:	e3e080e7          	jalr	-450(ra) # 80002aae <argint>
  acquire(&tickslock);
    80002c78:	00014517          	auipc	a0,0x14
    80002c7c:	d0850513          	addi	a0,a0,-760 # 80016980 <tickslock>
    80002c80:	ffffe097          	auipc	ra,0xffffe
    80002c84:	f50080e7          	jalr	-176(ra) # 80000bd0 <acquire>
  ticks0 = ticks;
    80002c88:	00006917          	auipc	s2,0x6
    80002c8c:	c5892903          	lw	s2,-936(s2) # 800088e0 <ticks>
  while(ticks - ticks0 < n){
    80002c90:	fcc42783          	lw	a5,-52(s0)
    80002c94:	cf9d                	beqz	a5,80002cd2 <sys_sleep+0x76>
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002c96:	00014997          	auipc	s3,0x14
    80002c9a:	cea98993          	addi	s3,s3,-790 # 80016980 <tickslock>
    80002c9e:	00006497          	auipc	s1,0x6
    80002ca2:	c4248493          	addi	s1,s1,-958 # 800088e0 <ticks>
    if(killed(myproc())){
    80002ca6:	fffff097          	auipc	ra,0xfffff
    80002caa:	cee080e7          	jalr	-786(ra) # 80001994 <myproc>
    80002cae:	fffff097          	auipc	ra,0xfffff
    80002cb2:	636080e7          	jalr	1590(ra) # 800022e4 <killed>
    80002cb6:	ed15                	bnez	a0,80002cf2 <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80002cb8:	85ce                	mv	a1,s3
    80002cba:	8526                	mv	a0,s1
    80002cbc:	fffff097          	auipc	ra,0xfffff
    80002cc0:	380080e7          	jalr	896(ra) # 8000203c <sleep>
  while(ticks - ticks0 < n){
    80002cc4:	409c                	lw	a5,0(s1)
    80002cc6:	412787bb          	subw	a5,a5,s2
    80002cca:	fcc42703          	lw	a4,-52(s0)
    80002cce:	fce7ece3          	bltu	a5,a4,80002ca6 <sys_sleep+0x4a>
  }
  release(&tickslock);
    80002cd2:	00014517          	auipc	a0,0x14
    80002cd6:	cae50513          	addi	a0,a0,-850 # 80016980 <tickslock>
    80002cda:	ffffe097          	auipc	ra,0xffffe
    80002cde:	faa080e7          	jalr	-86(ra) # 80000c84 <release>
  return 0;
    80002ce2:	4501                	li	a0,0
}
    80002ce4:	70e2                	ld	ra,56(sp)
    80002ce6:	7442                	ld	s0,48(sp)
    80002ce8:	74a2                	ld	s1,40(sp)
    80002cea:	7902                	ld	s2,32(sp)
    80002cec:	69e2                	ld	s3,24(sp)
    80002cee:	6121                	addi	sp,sp,64
    80002cf0:	8082                	ret
      release(&tickslock);
    80002cf2:	00014517          	auipc	a0,0x14
    80002cf6:	c8e50513          	addi	a0,a0,-882 # 80016980 <tickslock>
    80002cfa:	ffffe097          	auipc	ra,0xffffe
    80002cfe:	f8a080e7          	jalr	-118(ra) # 80000c84 <release>
      return -1;
    80002d02:	557d                	li	a0,-1
    80002d04:	b7c5                	j	80002ce4 <sys_sleep+0x88>

0000000080002d06 <sys_kill>:

uint64
sys_kill(void)
{
    80002d06:	1101                	addi	sp,sp,-32
    80002d08:	ec06                	sd	ra,24(sp)
    80002d0a:	e822                	sd	s0,16(sp)
    80002d0c:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80002d0e:	fec40593          	addi	a1,s0,-20
    80002d12:	4501                	li	a0,0
    80002d14:	00000097          	auipc	ra,0x0
    80002d18:	d9a080e7          	jalr	-614(ra) # 80002aae <argint>
  return kill(pid);
    80002d1c:	fec42503          	lw	a0,-20(s0)
    80002d20:	fffff097          	auipc	ra,0xfffff
    80002d24:	526080e7          	jalr	1318(ra) # 80002246 <kill>
}
    80002d28:	60e2                	ld	ra,24(sp)
    80002d2a:	6442                	ld	s0,16(sp)
    80002d2c:	6105                	addi	sp,sp,32
    80002d2e:	8082                	ret

0000000080002d30 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002d30:	1101                	addi	sp,sp,-32
    80002d32:	ec06                	sd	ra,24(sp)
    80002d34:	e822                	sd	s0,16(sp)
    80002d36:	e426                	sd	s1,8(sp)
    80002d38:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002d3a:	00014517          	auipc	a0,0x14
    80002d3e:	c4650513          	addi	a0,a0,-954 # 80016980 <tickslock>
    80002d42:	ffffe097          	auipc	ra,0xffffe
    80002d46:	e8e080e7          	jalr	-370(ra) # 80000bd0 <acquire>
  xticks = ticks;
    80002d4a:	00006497          	auipc	s1,0x6
    80002d4e:	b964a483          	lw	s1,-1130(s1) # 800088e0 <ticks>
  release(&tickslock);
    80002d52:	00014517          	auipc	a0,0x14
    80002d56:	c2e50513          	addi	a0,a0,-978 # 80016980 <tickslock>
    80002d5a:	ffffe097          	auipc	ra,0xffffe
    80002d5e:	f2a080e7          	jalr	-214(ra) # 80000c84 <release>
  return xticks;
}
    80002d62:	02049513          	slli	a0,s1,0x20
    80002d66:	9101                	srli	a0,a0,0x20
    80002d68:	60e2                	ld	ra,24(sp)
    80002d6a:	6442                	ld	s0,16(sp)
    80002d6c:	64a2                	ld	s1,8(sp)
    80002d6e:	6105                	addi	sp,sp,32
    80002d70:	8082                	ret

0000000080002d72 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002d72:	7179                	addi	sp,sp,-48
    80002d74:	f406                	sd	ra,40(sp)
    80002d76:	f022                	sd	s0,32(sp)
    80002d78:	ec26                	sd	s1,24(sp)
    80002d7a:	e84a                	sd	s2,16(sp)
    80002d7c:	e44e                	sd	s3,8(sp)
    80002d7e:	e052                	sd	s4,0(sp)
    80002d80:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002d82:	00005597          	auipc	a1,0x5
    80002d86:	79e58593          	addi	a1,a1,1950 # 80008520 <syscalls+0xb0>
    80002d8a:	00014517          	auipc	a0,0x14
    80002d8e:	c0e50513          	addi	a0,a0,-1010 # 80016998 <bcache>
    80002d92:	ffffe097          	auipc	ra,0xffffe
    80002d96:	dae080e7          	jalr	-594(ra) # 80000b40 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002d9a:	0001c797          	auipc	a5,0x1c
    80002d9e:	bfe78793          	addi	a5,a5,-1026 # 8001e998 <bcache+0x8000>
    80002da2:	0001c717          	auipc	a4,0x1c
    80002da6:	e5e70713          	addi	a4,a4,-418 # 8001ec00 <bcache+0x8268>
    80002daa:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002dae:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002db2:	00014497          	auipc	s1,0x14
    80002db6:	bfe48493          	addi	s1,s1,-1026 # 800169b0 <bcache+0x18>
    b->next = bcache.head.next;
    80002dba:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002dbc:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002dbe:	00005a17          	auipc	s4,0x5
    80002dc2:	76aa0a13          	addi	s4,s4,1898 # 80008528 <syscalls+0xb8>
    b->next = bcache.head.next;
    80002dc6:	2b893783          	ld	a5,696(s2)
    80002dca:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002dcc:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002dd0:	85d2                	mv	a1,s4
    80002dd2:	01048513          	addi	a0,s1,16
    80002dd6:	00001097          	auipc	ra,0x1
    80002dda:	496080e7          	jalr	1174(ra) # 8000426c <initsleeplock>
    bcache.head.next->prev = b;
    80002dde:	2b893783          	ld	a5,696(s2)
    80002de2:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002de4:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002de8:	45848493          	addi	s1,s1,1112
    80002dec:	fd349de3          	bne	s1,s3,80002dc6 <binit+0x54>
  }
}
    80002df0:	70a2                	ld	ra,40(sp)
    80002df2:	7402                	ld	s0,32(sp)
    80002df4:	64e2                	ld	s1,24(sp)
    80002df6:	6942                	ld	s2,16(sp)
    80002df8:	69a2                	ld	s3,8(sp)
    80002dfa:	6a02                	ld	s4,0(sp)
    80002dfc:	6145                	addi	sp,sp,48
    80002dfe:	8082                	ret

0000000080002e00 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002e00:	7179                	addi	sp,sp,-48
    80002e02:	f406                	sd	ra,40(sp)
    80002e04:	f022                	sd	s0,32(sp)
    80002e06:	ec26                	sd	s1,24(sp)
    80002e08:	e84a                	sd	s2,16(sp)
    80002e0a:	e44e                	sd	s3,8(sp)
    80002e0c:	1800                	addi	s0,sp,48
    80002e0e:	892a                	mv	s2,a0
    80002e10:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80002e12:	00014517          	auipc	a0,0x14
    80002e16:	b8650513          	addi	a0,a0,-1146 # 80016998 <bcache>
    80002e1a:	ffffe097          	auipc	ra,0xffffe
    80002e1e:	db6080e7          	jalr	-586(ra) # 80000bd0 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002e22:	0001c497          	auipc	s1,0x1c
    80002e26:	e2e4b483          	ld	s1,-466(s1) # 8001ec50 <bcache+0x82b8>
    80002e2a:	0001c797          	auipc	a5,0x1c
    80002e2e:	dd678793          	addi	a5,a5,-554 # 8001ec00 <bcache+0x8268>
    80002e32:	02f48f63          	beq	s1,a5,80002e70 <bread+0x70>
    80002e36:	873e                	mv	a4,a5
    80002e38:	a021                	j	80002e40 <bread+0x40>
    80002e3a:	68a4                	ld	s1,80(s1)
    80002e3c:	02e48a63          	beq	s1,a4,80002e70 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002e40:	449c                	lw	a5,8(s1)
    80002e42:	ff279ce3          	bne	a5,s2,80002e3a <bread+0x3a>
    80002e46:	44dc                	lw	a5,12(s1)
    80002e48:	ff3799e3          	bne	a5,s3,80002e3a <bread+0x3a>
      b->refcnt++;
    80002e4c:	40bc                	lw	a5,64(s1)
    80002e4e:	2785                	addiw	a5,a5,1
    80002e50:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002e52:	00014517          	auipc	a0,0x14
    80002e56:	b4650513          	addi	a0,a0,-1210 # 80016998 <bcache>
    80002e5a:	ffffe097          	auipc	ra,0xffffe
    80002e5e:	e2a080e7          	jalr	-470(ra) # 80000c84 <release>
      acquiresleep(&b->lock);
    80002e62:	01048513          	addi	a0,s1,16
    80002e66:	00001097          	auipc	ra,0x1
    80002e6a:	440080e7          	jalr	1088(ra) # 800042a6 <acquiresleep>
      return b;
    80002e6e:	a8b9                	j	80002ecc <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002e70:	0001c497          	auipc	s1,0x1c
    80002e74:	dd84b483          	ld	s1,-552(s1) # 8001ec48 <bcache+0x82b0>
    80002e78:	0001c797          	auipc	a5,0x1c
    80002e7c:	d8878793          	addi	a5,a5,-632 # 8001ec00 <bcache+0x8268>
    80002e80:	00f48863          	beq	s1,a5,80002e90 <bread+0x90>
    80002e84:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002e86:	40bc                	lw	a5,64(s1)
    80002e88:	cf81                	beqz	a5,80002ea0 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002e8a:	64a4                	ld	s1,72(s1)
    80002e8c:	fee49de3          	bne	s1,a4,80002e86 <bread+0x86>
  panic("bget: no buffers");
    80002e90:	00005517          	auipc	a0,0x5
    80002e94:	6a050513          	addi	a0,a0,1696 # 80008530 <syscalls+0xc0>
    80002e98:	ffffd097          	auipc	ra,0xffffd
    80002e9c:	6a2080e7          	jalr	1698(ra) # 8000053a <panic>
      b->dev = dev;
    80002ea0:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80002ea4:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80002ea8:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80002eac:	4785                	li	a5,1
    80002eae:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002eb0:	00014517          	auipc	a0,0x14
    80002eb4:	ae850513          	addi	a0,a0,-1304 # 80016998 <bcache>
    80002eb8:	ffffe097          	auipc	ra,0xffffe
    80002ebc:	dcc080e7          	jalr	-564(ra) # 80000c84 <release>
      acquiresleep(&b->lock);
    80002ec0:	01048513          	addi	a0,s1,16
    80002ec4:	00001097          	auipc	ra,0x1
    80002ec8:	3e2080e7          	jalr	994(ra) # 800042a6 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80002ecc:	409c                	lw	a5,0(s1)
    80002ece:	cb89                	beqz	a5,80002ee0 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80002ed0:	8526                	mv	a0,s1
    80002ed2:	70a2                	ld	ra,40(sp)
    80002ed4:	7402                	ld	s0,32(sp)
    80002ed6:	64e2                	ld	s1,24(sp)
    80002ed8:	6942                	ld	s2,16(sp)
    80002eda:	69a2                	ld	s3,8(sp)
    80002edc:	6145                	addi	sp,sp,48
    80002ede:	8082                	ret
    virtio_disk_rw(b, 0);
    80002ee0:	4581                	li	a1,0
    80002ee2:	8526                	mv	a0,s1
    80002ee4:	00003097          	auipc	ra,0x3
    80002ee8:	f7e080e7          	jalr	-130(ra) # 80005e62 <virtio_disk_rw>
    b->valid = 1;
    80002eec:	4785                	li	a5,1
    80002eee:	c09c                	sw	a5,0(s1)
  return b;
    80002ef0:	b7c5                	j	80002ed0 <bread+0xd0>

0000000080002ef2 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80002ef2:	1101                	addi	sp,sp,-32
    80002ef4:	ec06                	sd	ra,24(sp)
    80002ef6:	e822                	sd	s0,16(sp)
    80002ef8:	e426                	sd	s1,8(sp)
    80002efa:	1000                	addi	s0,sp,32
    80002efc:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002efe:	0541                	addi	a0,a0,16
    80002f00:	00001097          	auipc	ra,0x1
    80002f04:	440080e7          	jalr	1088(ra) # 80004340 <holdingsleep>
    80002f08:	cd01                	beqz	a0,80002f20 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80002f0a:	4585                	li	a1,1
    80002f0c:	8526                	mv	a0,s1
    80002f0e:	00003097          	auipc	ra,0x3
    80002f12:	f54080e7          	jalr	-172(ra) # 80005e62 <virtio_disk_rw>
}
    80002f16:	60e2                	ld	ra,24(sp)
    80002f18:	6442                	ld	s0,16(sp)
    80002f1a:	64a2                	ld	s1,8(sp)
    80002f1c:	6105                	addi	sp,sp,32
    80002f1e:	8082                	ret
    panic("bwrite");
    80002f20:	00005517          	auipc	a0,0x5
    80002f24:	62850513          	addi	a0,a0,1576 # 80008548 <syscalls+0xd8>
    80002f28:	ffffd097          	auipc	ra,0xffffd
    80002f2c:	612080e7          	jalr	1554(ra) # 8000053a <panic>

0000000080002f30 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80002f30:	1101                	addi	sp,sp,-32
    80002f32:	ec06                	sd	ra,24(sp)
    80002f34:	e822                	sd	s0,16(sp)
    80002f36:	e426                	sd	s1,8(sp)
    80002f38:	e04a                	sd	s2,0(sp)
    80002f3a:	1000                	addi	s0,sp,32
    80002f3c:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002f3e:	01050913          	addi	s2,a0,16
    80002f42:	854a                	mv	a0,s2
    80002f44:	00001097          	auipc	ra,0x1
    80002f48:	3fc080e7          	jalr	1020(ra) # 80004340 <holdingsleep>
    80002f4c:	c925                	beqz	a0,80002fbc <brelse+0x8c>
    panic("brelse");

  releasesleep(&b->lock);
    80002f4e:	854a                	mv	a0,s2
    80002f50:	00001097          	auipc	ra,0x1
    80002f54:	3ac080e7          	jalr	940(ra) # 800042fc <releasesleep>

  acquire(&bcache.lock);
    80002f58:	00014517          	auipc	a0,0x14
    80002f5c:	a4050513          	addi	a0,a0,-1472 # 80016998 <bcache>
    80002f60:	ffffe097          	auipc	ra,0xffffe
    80002f64:	c70080e7          	jalr	-912(ra) # 80000bd0 <acquire>
  b->refcnt--;
    80002f68:	40bc                	lw	a5,64(s1)
    80002f6a:	37fd                	addiw	a5,a5,-1
    80002f6c:	0007871b          	sext.w	a4,a5
    80002f70:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80002f72:	e71d                	bnez	a4,80002fa0 <brelse+0x70>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80002f74:	68b8                	ld	a4,80(s1)
    80002f76:	64bc                	ld	a5,72(s1)
    80002f78:	e73c                	sd	a5,72(a4)
    b->prev->next = b->next;
    80002f7a:	68b8                	ld	a4,80(s1)
    80002f7c:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80002f7e:	0001c797          	auipc	a5,0x1c
    80002f82:	a1a78793          	addi	a5,a5,-1510 # 8001e998 <bcache+0x8000>
    80002f86:	2b87b703          	ld	a4,696(a5)
    80002f8a:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80002f8c:	0001c717          	auipc	a4,0x1c
    80002f90:	c7470713          	addi	a4,a4,-908 # 8001ec00 <bcache+0x8268>
    80002f94:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80002f96:	2b87b703          	ld	a4,696(a5)
    80002f9a:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80002f9c:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80002fa0:	00014517          	auipc	a0,0x14
    80002fa4:	9f850513          	addi	a0,a0,-1544 # 80016998 <bcache>
    80002fa8:	ffffe097          	auipc	ra,0xffffe
    80002fac:	cdc080e7          	jalr	-804(ra) # 80000c84 <release>
}
    80002fb0:	60e2                	ld	ra,24(sp)
    80002fb2:	6442                	ld	s0,16(sp)
    80002fb4:	64a2                	ld	s1,8(sp)
    80002fb6:	6902                	ld	s2,0(sp)
    80002fb8:	6105                	addi	sp,sp,32
    80002fba:	8082                	ret
    panic("brelse");
    80002fbc:	00005517          	auipc	a0,0x5
    80002fc0:	59450513          	addi	a0,a0,1428 # 80008550 <syscalls+0xe0>
    80002fc4:	ffffd097          	auipc	ra,0xffffd
    80002fc8:	576080e7          	jalr	1398(ra) # 8000053a <panic>

0000000080002fcc <bpin>:

void
bpin(struct buf *b) {
    80002fcc:	1101                	addi	sp,sp,-32
    80002fce:	ec06                	sd	ra,24(sp)
    80002fd0:	e822                	sd	s0,16(sp)
    80002fd2:	e426                	sd	s1,8(sp)
    80002fd4:	1000                	addi	s0,sp,32
    80002fd6:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80002fd8:	00014517          	auipc	a0,0x14
    80002fdc:	9c050513          	addi	a0,a0,-1600 # 80016998 <bcache>
    80002fe0:	ffffe097          	auipc	ra,0xffffe
    80002fe4:	bf0080e7          	jalr	-1040(ra) # 80000bd0 <acquire>
  b->refcnt++;
    80002fe8:	40bc                	lw	a5,64(s1)
    80002fea:	2785                	addiw	a5,a5,1
    80002fec:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80002fee:	00014517          	auipc	a0,0x14
    80002ff2:	9aa50513          	addi	a0,a0,-1622 # 80016998 <bcache>
    80002ff6:	ffffe097          	auipc	ra,0xffffe
    80002ffa:	c8e080e7          	jalr	-882(ra) # 80000c84 <release>
}
    80002ffe:	60e2                	ld	ra,24(sp)
    80003000:	6442                	ld	s0,16(sp)
    80003002:	64a2                	ld	s1,8(sp)
    80003004:	6105                	addi	sp,sp,32
    80003006:	8082                	ret

0000000080003008 <bunpin>:

void
bunpin(struct buf *b) {
    80003008:	1101                	addi	sp,sp,-32
    8000300a:	ec06                	sd	ra,24(sp)
    8000300c:	e822                	sd	s0,16(sp)
    8000300e:	e426                	sd	s1,8(sp)
    80003010:	1000                	addi	s0,sp,32
    80003012:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003014:	00014517          	auipc	a0,0x14
    80003018:	98450513          	addi	a0,a0,-1660 # 80016998 <bcache>
    8000301c:	ffffe097          	auipc	ra,0xffffe
    80003020:	bb4080e7          	jalr	-1100(ra) # 80000bd0 <acquire>
  b->refcnt--;
    80003024:	40bc                	lw	a5,64(s1)
    80003026:	37fd                	addiw	a5,a5,-1
    80003028:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000302a:	00014517          	auipc	a0,0x14
    8000302e:	96e50513          	addi	a0,a0,-1682 # 80016998 <bcache>
    80003032:	ffffe097          	auipc	ra,0xffffe
    80003036:	c52080e7          	jalr	-942(ra) # 80000c84 <release>
}
    8000303a:	60e2                	ld	ra,24(sp)
    8000303c:	6442                	ld	s0,16(sp)
    8000303e:	64a2                	ld	s1,8(sp)
    80003040:	6105                	addi	sp,sp,32
    80003042:	8082                	ret

0000000080003044 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003044:	1101                	addi	sp,sp,-32
    80003046:	ec06                	sd	ra,24(sp)
    80003048:	e822                	sd	s0,16(sp)
    8000304a:	e426                	sd	s1,8(sp)
    8000304c:	e04a                	sd	s2,0(sp)
    8000304e:	1000                	addi	s0,sp,32
    80003050:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003052:	00d5d59b          	srliw	a1,a1,0xd
    80003056:	0001c797          	auipc	a5,0x1c
    8000305a:	01e7a783          	lw	a5,30(a5) # 8001f074 <sb+0x1c>
    8000305e:	9dbd                	addw	a1,a1,a5
    80003060:	00000097          	auipc	ra,0x0
    80003064:	da0080e7          	jalr	-608(ra) # 80002e00 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003068:	0074f713          	andi	a4,s1,7
    8000306c:	4785                	li	a5,1
    8000306e:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003072:	14ce                	slli	s1,s1,0x33
    80003074:	90d9                	srli	s1,s1,0x36
    80003076:	00950733          	add	a4,a0,s1
    8000307a:	05874703          	lbu	a4,88(a4)
    8000307e:	00e7f6b3          	and	a3,a5,a4
    80003082:	c69d                	beqz	a3,800030b0 <bfree+0x6c>
    80003084:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003086:	94aa                	add	s1,s1,a0
    80003088:	fff7c793          	not	a5,a5
    8000308c:	8f7d                	and	a4,a4,a5
    8000308e:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    80003092:	00001097          	auipc	ra,0x1
    80003096:	0f6080e7          	jalr	246(ra) # 80004188 <log_write>
  brelse(bp);
    8000309a:	854a                	mv	a0,s2
    8000309c:	00000097          	auipc	ra,0x0
    800030a0:	e94080e7          	jalr	-364(ra) # 80002f30 <brelse>
}
    800030a4:	60e2                	ld	ra,24(sp)
    800030a6:	6442                	ld	s0,16(sp)
    800030a8:	64a2                	ld	s1,8(sp)
    800030aa:	6902                	ld	s2,0(sp)
    800030ac:	6105                	addi	sp,sp,32
    800030ae:	8082                	ret
    panic("freeing free block");
    800030b0:	00005517          	auipc	a0,0x5
    800030b4:	4a850513          	addi	a0,a0,1192 # 80008558 <syscalls+0xe8>
    800030b8:	ffffd097          	auipc	ra,0xffffd
    800030bc:	482080e7          	jalr	1154(ra) # 8000053a <panic>

00000000800030c0 <balloc>:
{
    800030c0:	711d                	addi	sp,sp,-96
    800030c2:	ec86                	sd	ra,88(sp)
    800030c4:	e8a2                	sd	s0,80(sp)
    800030c6:	e4a6                	sd	s1,72(sp)
    800030c8:	e0ca                	sd	s2,64(sp)
    800030ca:	fc4e                	sd	s3,56(sp)
    800030cc:	f852                	sd	s4,48(sp)
    800030ce:	f456                	sd	s5,40(sp)
    800030d0:	f05a                	sd	s6,32(sp)
    800030d2:	ec5e                	sd	s7,24(sp)
    800030d4:	e862                	sd	s8,16(sp)
    800030d6:	e466                	sd	s9,8(sp)
    800030d8:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800030da:	0001c797          	auipc	a5,0x1c
    800030de:	f827a783          	lw	a5,-126(a5) # 8001f05c <sb+0x4>
    800030e2:	cff5                	beqz	a5,800031de <balloc+0x11e>
    800030e4:	8baa                	mv	s7,a0
    800030e6:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800030e8:	0001cb17          	auipc	s6,0x1c
    800030ec:	f70b0b13          	addi	s6,s6,-144 # 8001f058 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800030f0:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800030f2:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800030f4:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800030f6:	6c89                	lui	s9,0x2
    800030f8:	a061                	j	80003180 <balloc+0xc0>
        bp->data[bi/8] |= m;  // Mark block in use.
    800030fa:	97ca                	add	a5,a5,s2
    800030fc:	8e55                	or	a2,a2,a3
    800030fe:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    80003102:	854a                	mv	a0,s2
    80003104:	00001097          	auipc	ra,0x1
    80003108:	084080e7          	jalr	132(ra) # 80004188 <log_write>
        brelse(bp);
    8000310c:	854a                	mv	a0,s2
    8000310e:	00000097          	auipc	ra,0x0
    80003112:	e22080e7          	jalr	-478(ra) # 80002f30 <brelse>
  bp = bread(dev, bno);
    80003116:	85a6                	mv	a1,s1
    80003118:	855e                	mv	a0,s7
    8000311a:	00000097          	auipc	ra,0x0
    8000311e:	ce6080e7          	jalr	-794(ra) # 80002e00 <bread>
    80003122:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003124:	40000613          	li	a2,1024
    80003128:	4581                	li	a1,0
    8000312a:	05850513          	addi	a0,a0,88
    8000312e:	ffffe097          	auipc	ra,0xffffe
    80003132:	b9e080e7          	jalr	-1122(ra) # 80000ccc <memset>
  log_write(bp);
    80003136:	854a                	mv	a0,s2
    80003138:	00001097          	auipc	ra,0x1
    8000313c:	050080e7          	jalr	80(ra) # 80004188 <log_write>
  brelse(bp);
    80003140:	854a                	mv	a0,s2
    80003142:	00000097          	auipc	ra,0x0
    80003146:	dee080e7          	jalr	-530(ra) # 80002f30 <brelse>
}
    8000314a:	8526                	mv	a0,s1
    8000314c:	60e6                	ld	ra,88(sp)
    8000314e:	6446                	ld	s0,80(sp)
    80003150:	64a6                	ld	s1,72(sp)
    80003152:	6906                	ld	s2,64(sp)
    80003154:	79e2                	ld	s3,56(sp)
    80003156:	7a42                	ld	s4,48(sp)
    80003158:	7aa2                	ld	s5,40(sp)
    8000315a:	7b02                	ld	s6,32(sp)
    8000315c:	6be2                	ld	s7,24(sp)
    8000315e:	6c42                	ld	s8,16(sp)
    80003160:	6ca2                	ld	s9,8(sp)
    80003162:	6125                	addi	sp,sp,96
    80003164:	8082                	ret
    brelse(bp);
    80003166:	854a                	mv	a0,s2
    80003168:	00000097          	auipc	ra,0x0
    8000316c:	dc8080e7          	jalr	-568(ra) # 80002f30 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003170:	015c87bb          	addw	a5,s9,s5
    80003174:	00078a9b          	sext.w	s5,a5
    80003178:	004b2703          	lw	a4,4(s6)
    8000317c:	06eaf163          	bgeu	s5,a4,800031de <balloc+0x11e>
    bp = bread(dev, BBLOCK(b, sb));
    80003180:	41fad79b          	sraiw	a5,s5,0x1f
    80003184:	0137d79b          	srliw	a5,a5,0x13
    80003188:	015787bb          	addw	a5,a5,s5
    8000318c:	40d7d79b          	sraiw	a5,a5,0xd
    80003190:	01cb2583          	lw	a1,28(s6)
    80003194:	9dbd                	addw	a1,a1,a5
    80003196:	855e                	mv	a0,s7
    80003198:	00000097          	auipc	ra,0x0
    8000319c:	c68080e7          	jalr	-920(ra) # 80002e00 <bread>
    800031a0:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800031a2:	004b2503          	lw	a0,4(s6)
    800031a6:	000a849b          	sext.w	s1,s5
    800031aa:	8762                	mv	a4,s8
    800031ac:	faa4fde3          	bgeu	s1,a0,80003166 <balloc+0xa6>
      m = 1 << (bi % 8);
    800031b0:	00777693          	andi	a3,a4,7
    800031b4:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800031b8:	41f7579b          	sraiw	a5,a4,0x1f
    800031bc:	01d7d79b          	srliw	a5,a5,0x1d
    800031c0:	9fb9                	addw	a5,a5,a4
    800031c2:	4037d79b          	sraiw	a5,a5,0x3
    800031c6:	00f90633          	add	a2,s2,a5
    800031ca:	05864603          	lbu	a2,88(a2)
    800031ce:	00c6f5b3          	and	a1,a3,a2
    800031d2:	d585                	beqz	a1,800030fa <balloc+0x3a>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800031d4:	2705                	addiw	a4,a4,1
    800031d6:	2485                	addiw	s1,s1,1
    800031d8:	fd471ae3          	bne	a4,s4,800031ac <balloc+0xec>
    800031dc:	b769                	j	80003166 <balloc+0xa6>
  printf("balloc: out of blocks\n");
    800031de:	00005517          	auipc	a0,0x5
    800031e2:	39250513          	addi	a0,a0,914 # 80008570 <syscalls+0x100>
    800031e6:	ffffd097          	auipc	ra,0xffffd
    800031ea:	39e080e7          	jalr	926(ra) # 80000584 <printf>
  return 0;
    800031ee:	4481                	li	s1,0
    800031f0:	bfa9                	j	8000314a <balloc+0x8a>

00000000800031f2 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    800031f2:	7179                	addi	sp,sp,-48
    800031f4:	f406                	sd	ra,40(sp)
    800031f6:	f022                	sd	s0,32(sp)
    800031f8:	ec26                	sd	s1,24(sp)
    800031fa:	e84a                	sd	s2,16(sp)
    800031fc:	e44e                	sd	s3,8(sp)
    800031fe:	e052                	sd	s4,0(sp)
    80003200:	1800                	addi	s0,sp,48
    80003202:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003204:	47ad                	li	a5,11
    80003206:	02b7e863          	bltu	a5,a1,80003236 <bmap+0x44>
    if((addr = ip->addrs[bn]) == 0){
    8000320a:	02059793          	slli	a5,a1,0x20
    8000320e:	01e7d593          	srli	a1,a5,0x1e
    80003212:	00b504b3          	add	s1,a0,a1
    80003216:	0504a903          	lw	s2,80(s1)
    8000321a:	06091e63          	bnez	s2,80003296 <bmap+0xa4>
      addr = balloc(ip->dev);
    8000321e:	4108                	lw	a0,0(a0)
    80003220:	00000097          	auipc	ra,0x0
    80003224:	ea0080e7          	jalr	-352(ra) # 800030c0 <balloc>
    80003228:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    8000322c:	06090563          	beqz	s2,80003296 <bmap+0xa4>
        return 0;
      ip->addrs[bn] = addr;
    80003230:	0524a823          	sw	s2,80(s1)
    80003234:	a08d                	j	80003296 <bmap+0xa4>
    }
    return addr;
  }
  bn -= NDIRECT;
    80003236:	ff45849b          	addiw	s1,a1,-12
    8000323a:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    8000323e:	0ff00793          	li	a5,255
    80003242:	08e7e563          	bltu	a5,a4,800032cc <bmap+0xda>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80003246:	08052903          	lw	s2,128(a0)
    8000324a:	00091d63          	bnez	s2,80003264 <bmap+0x72>
      addr = balloc(ip->dev);
    8000324e:	4108                	lw	a0,0(a0)
    80003250:	00000097          	auipc	ra,0x0
    80003254:	e70080e7          	jalr	-400(ra) # 800030c0 <balloc>
    80003258:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    8000325c:	02090d63          	beqz	s2,80003296 <bmap+0xa4>
        return 0;
      ip->addrs[NDIRECT] = addr;
    80003260:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    80003264:	85ca                	mv	a1,s2
    80003266:	0009a503          	lw	a0,0(s3)
    8000326a:	00000097          	auipc	ra,0x0
    8000326e:	b96080e7          	jalr	-1130(ra) # 80002e00 <bread>
    80003272:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003274:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003278:	02049713          	slli	a4,s1,0x20
    8000327c:	01e75593          	srli	a1,a4,0x1e
    80003280:	00b784b3          	add	s1,a5,a1
    80003284:	0004a903          	lw	s2,0(s1)
    80003288:	02090063          	beqz	s2,800032a8 <bmap+0xb6>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    8000328c:	8552                	mv	a0,s4
    8000328e:	00000097          	auipc	ra,0x0
    80003292:	ca2080e7          	jalr	-862(ra) # 80002f30 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003296:	854a                	mv	a0,s2
    80003298:	70a2                	ld	ra,40(sp)
    8000329a:	7402                	ld	s0,32(sp)
    8000329c:	64e2                	ld	s1,24(sp)
    8000329e:	6942                	ld	s2,16(sp)
    800032a0:	69a2                	ld	s3,8(sp)
    800032a2:	6a02                	ld	s4,0(sp)
    800032a4:	6145                	addi	sp,sp,48
    800032a6:	8082                	ret
      addr = balloc(ip->dev);
    800032a8:	0009a503          	lw	a0,0(s3)
    800032ac:	00000097          	auipc	ra,0x0
    800032b0:	e14080e7          	jalr	-492(ra) # 800030c0 <balloc>
    800032b4:	0005091b          	sext.w	s2,a0
      if(addr){
    800032b8:	fc090ae3          	beqz	s2,8000328c <bmap+0x9a>
        a[bn] = addr;
    800032bc:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    800032c0:	8552                	mv	a0,s4
    800032c2:	00001097          	auipc	ra,0x1
    800032c6:	ec6080e7          	jalr	-314(ra) # 80004188 <log_write>
    800032ca:	b7c9                	j	8000328c <bmap+0x9a>
  panic("bmap: out of range");
    800032cc:	00005517          	auipc	a0,0x5
    800032d0:	2bc50513          	addi	a0,a0,700 # 80008588 <syscalls+0x118>
    800032d4:	ffffd097          	auipc	ra,0xffffd
    800032d8:	266080e7          	jalr	614(ra) # 8000053a <panic>

00000000800032dc <iget>:
{
    800032dc:	7179                	addi	sp,sp,-48
    800032de:	f406                	sd	ra,40(sp)
    800032e0:	f022                	sd	s0,32(sp)
    800032e2:	ec26                	sd	s1,24(sp)
    800032e4:	e84a                	sd	s2,16(sp)
    800032e6:	e44e                	sd	s3,8(sp)
    800032e8:	e052                	sd	s4,0(sp)
    800032ea:	1800                	addi	s0,sp,48
    800032ec:	89aa                	mv	s3,a0
    800032ee:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800032f0:	0001c517          	auipc	a0,0x1c
    800032f4:	d8850513          	addi	a0,a0,-632 # 8001f078 <itable>
    800032f8:	ffffe097          	auipc	ra,0xffffe
    800032fc:	8d8080e7          	jalr	-1832(ra) # 80000bd0 <acquire>
  empty = 0;
    80003300:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003302:	0001c497          	auipc	s1,0x1c
    80003306:	d8e48493          	addi	s1,s1,-626 # 8001f090 <itable+0x18>
    8000330a:	0001e697          	auipc	a3,0x1e
    8000330e:	81668693          	addi	a3,a3,-2026 # 80020b20 <log>
    80003312:	a039                	j	80003320 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003314:	02090b63          	beqz	s2,8000334a <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003318:	08848493          	addi	s1,s1,136
    8000331c:	02d48a63          	beq	s1,a3,80003350 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003320:	449c                	lw	a5,8(s1)
    80003322:	fef059e3          	blez	a5,80003314 <iget+0x38>
    80003326:	4098                	lw	a4,0(s1)
    80003328:	ff3716e3          	bne	a4,s3,80003314 <iget+0x38>
    8000332c:	40d8                	lw	a4,4(s1)
    8000332e:	ff4713e3          	bne	a4,s4,80003314 <iget+0x38>
      ip->ref++;
    80003332:	2785                	addiw	a5,a5,1
    80003334:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003336:	0001c517          	auipc	a0,0x1c
    8000333a:	d4250513          	addi	a0,a0,-702 # 8001f078 <itable>
    8000333e:	ffffe097          	auipc	ra,0xffffe
    80003342:	946080e7          	jalr	-1722(ra) # 80000c84 <release>
      return ip;
    80003346:	8926                	mv	s2,s1
    80003348:	a03d                	j	80003376 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000334a:	f7f9                	bnez	a5,80003318 <iget+0x3c>
    8000334c:	8926                	mv	s2,s1
    8000334e:	b7e9                	j	80003318 <iget+0x3c>
  if(empty == 0)
    80003350:	02090c63          	beqz	s2,80003388 <iget+0xac>
  ip->dev = dev;
    80003354:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003358:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000335c:	4785                	li	a5,1
    8000335e:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003362:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003366:	0001c517          	auipc	a0,0x1c
    8000336a:	d1250513          	addi	a0,a0,-750 # 8001f078 <itable>
    8000336e:	ffffe097          	auipc	ra,0xffffe
    80003372:	916080e7          	jalr	-1770(ra) # 80000c84 <release>
}
    80003376:	854a                	mv	a0,s2
    80003378:	70a2                	ld	ra,40(sp)
    8000337a:	7402                	ld	s0,32(sp)
    8000337c:	64e2                	ld	s1,24(sp)
    8000337e:	6942                	ld	s2,16(sp)
    80003380:	69a2                	ld	s3,8(sp)
    80003382:	6a02                	ld	s4,0(sp)
    80003384:	6145                	addi	sp,sp,48
    80003386:	8082                	ret
    panic("iget: no inodes");
    80003388:	00005517          	auipc	a0,0x5
    8000338c:	21850513          	addi	a0,a0,536 # 800085a0 <syscalls+0x130>
    80003390:	ffffd097          	auipc	ra,0xffffd
    80003394:	1aa080e7          	jalr	426(ra) # 8000053a <panic>

0000000080003398 <fsinit>:
fsinit(int dev) {
    80003398:	7179                	addi	sp,sp,-48
    8000339a:	f406                	sd	ra,40(sp)
    8000339c:	f022                	sd	s0,32(sp)
    8000339e:	ec26                	sd	s1,24(sp)
    800033a0:	e84a                	sd	s2,16(sp)
    800033a2:	e44e                	sd	s3,8(sp)
    800033a4:	1800                	addi	s0,sp,48
    800033a6:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800033a8:	4585                	li	a1,1
    800033aa:	00000097          	auipc	ra,0x0
    800033ae:	a56080e7          	jalr	-1450(ra) # 80002e00 <bread>
    800033b2:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800033b4:	0001c997          	auipc	s3,0x1c
    800033b8:	ca498993          	addi	s3,s3,-860 # 8001f058 <sb>
    800033bc:	02000613          	li	a2,32
    800033c0:	05850593          	addi	a1,a0,88
    800033c4:	854e                	mv	a0,s3
    800033c6:	ffffe097          	auipc	ra,0xffffe
    800033ca:	962080e7          	jalr	-1694(ra) # 80000d28 <memmove>
  brelse(bp);
    800033ce:	8526                	mv	a0,s1
    800033d0:	00000097          	auipc	ra,0x0
    800033d4:	b60080e7          	jalr	-1184(ra) # 80002f30 <brelse>
  if(sb.magic != FSMAGIC)
    800033d8:	0009a703          	lw	a4,0(s3)
    800033dc:	102037b7          	lui	a5,0x10203
    800033e0:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800033e4:	02f71263          	bne	a4,a5,80003408 <fsinit+0x70>
  initlog(dev, &sb);
    800033e8:	0001c597          	auipc	a1,0x1c
    800033ec:	c7058593          	addi	a1,a1,-912 # 8001f058 <sb>
    800033f0:	854a                	mv	a0,s2
    800033f2:	00001097          	auipc	ra,0x1
    800033f6:	b2c080e7          	jalr	-1236(ra) # 80003f1e <initlog>
}
    800033fa:	70a2                	ld	ra,40(sp)
    800033fc:	7402                	ld	s0,32(sp)
    800033fe:	64e2                	ld	s1,24(sp)
    80003400:	6942                	ld	s2,16(sp)
    80003402:	69a2                	ld	s3,8(sp)
    80003404:	6145                	addi	sp,sp,48
    80003406:	8082                	ret
    panic("invalid file system");
    80003408:	00005517          	auipc	a0,0x5
    8000340c:	1a850513          	addi	a0,a0,424 # 800085b0 <syscalls+0x140>
    80003410:	ffffd097          	auipc	ra,0xffffd
    80003414:	12a080e7          	jalr	298(ra) # 8000053a <panic>

0000000080003418 <iinit>:
{
    80003418:	7179                	addi	sp,sp,-48
    8000341a:	f406                	sd	ra,40(sp)
    8000341c:	f022                	sd	s0,32(sp)
    8000341e:	ec26                	sd	s1,24(sp)
    80003420:	e84a                	sd	s2,16(sp)
    80003422:	e44e                	sd	s3,8(sp)
    80003424:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003426:	00005597          	auipc	a1,0x5
    8000342a:	1a258593          	addi	a1,a1,418 # 800085c8 <syscalls+0x158>
    8000342e:	0001c517          	auipc	a0,0x1c
    80003432:	c4a50513          	addi	a0,a0,-950 # 8001f078 <itable>
    80003436:	ffffd097          	auipc	ra,0xffffd
    8000343a:	70a080e7          	jalr	1802(ra) # 80000b40 <initlock>
  for(i = 0; i < NINODE; i++) {
    8000343e:	0001c497          	auipc	s1,0x1c
    80003442:	c6248493          	addi	s1,s1,-926 # 8001f0a0 <itable+0x28>
    80003446:	0001d997          	auipc	s3,0x1d
    8000344a:	6ea98993          	addi	s3,s3,1770 # 80020b30 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    8000344e:	00005917          	auipc	s2,0x5
    80003452:	18290913          	addi	s2,s2,386 # 800085d0 <syscalls+0x160>
    80003456:	85ca                	mv	a1,s2
    80003458:	8526                	mv	a0,s1
    8000345a:	00001097          	auipc	ra,0x1
    8000345e:	e12080e7          	jalr	-494(ra) # 8000426c <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003462:	08848493          	addi	s1,s1,136
    80003466:	ff3498e3          	bne	s1,s3,80003456 <iinit+0x3e>
}
    8000346a:	70a2                	ld	ra,40(sp)
    8000346c:	7402                	ld	s0,32(sp)
    8000346e:	64e2                	ld	s1,24(sp)
    80003470:	6942                	ld	s2,16(sp)
    80003472:	69a2                	ld	s3,8(sp)
    80003474:	6145                	addi	sp,sp,48
    80003476:	8082                	ret

0000000080003478 <ialloc>:
{
    80003478:	7139                	addi	sp,sp,-64
    8000347a:	fc06                	sd	ra,56(sp)
    8000347c:	f822                	sd	s0,48(sp)
    8000347e:	f426                	sd	s1,40(sp)
    80003480:	f04a                	sd	s2,32(sp)
    80003482:	ec4e                	sd	s3,24(sp)
    80003484:	e852                	sd	s4,16(sp)
    80003486:	e456                	sd	s5,8(sp)
    80003488:	e05a                	sd	s6,0(sp)
    8000348a:	0080                	addi	s0,sp,64
  for(inum = 1; inum < sb.ninodes; inum++){
    8000348c:	0001c717          	auipc	a4,0x1c
    80003490:	bd872703          	lw	a4,-1064(a4) # 8001f064 <sb+0xc>
    80003494:	4785                	li	a5,1
    80003496:	04e7f863          	bgeu	a5,a4,800034e6 <ialloc+0x6e>
    8000349a:	8aaa                	mv	s5,a0
    8000349c:	8b2e                	mv	s6,a1
    8000349e:	4905                	li	s2,1
    bp = bread(dev, IBLOCK(inum, sb));
    800034a0:	0001ca17          	auipc	s4,0x1c
    800034a4:	bb8a0a13          	addi	s4,s4,-1096 # 8001f058 <sb>
    800034a8:	00495593          	srli	a1,s2,0x4
    800034ac:	018a2783          	lw	a5,24(s4)
    800034b0:	9dbd                	addw	a1,a1,a5
    800034b2:	8556                	mv	a0,s5
    800034b4:	00000097          	auipc	ra,0x0
    800034b8:	94c080e7          	jalr	-1716(ra) # 80002e00 <bread>
    800034bc:	84aa                	mv	s1,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800034be:	05850993          	addi	s3,a0,88
    800034c2:	00f97793          	andi	a5,s2,15
    800034c6:	079a                	slli	a5,a5,0x6
    800034c8:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800034ca:	00099783          	lh	a5,0(s3)
    800034ce:	cf9d                	beqz	a5,8000350c <ialloc+0x94>
    brelse(bp);
    800034d0:	00000097          	auipc	ra,0x0
    800034d4:	a60080e7          	jalr	-1440(ra) # 80002f30 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800034d8:	0905                	addi	s2,s2,1
    800034da:	00ca2703          	lw	a4,12(s4)
    800034de:	0009079b          	sext.w	a5,s2
    800034e2:	fce7e3e3          	bltu	a5,a4,800034a8 <ialloc+0x30>
  printf("ialloc: no inodes\n");
    800034e6:	00005517          	auipc	a0,0x5
    800034ea:	0f250513          	addi	a0,a0,242 # 800085d8 <syscalls+0x168>
    800034ee:	ffffd097          	auipc	ra,0xffffd
    800034f2:	096080e7          	jalr	150(ra) # 80000584 <printf>
  return 0;
    800034f6:	4501                	li	a0,0
}
    800034f8:	70e2                	ld	ra,56(sp)
    800034fa:	7442                	ld	s0,48(sp)
    800034fc:	74a2                	ld	s1,40(sp)
    800034fe:	7902                	ld	s2,32(sp)
    80003500:	69e2                	ld	s3,24(sp)
    80003502:	6a42                	ld	s4,16(sp)
    80003504:	6aa2                	ld	s5,8(sp)
    80003506:	6b02                	ld	s6,0(sp)
    80003508:	6121                	addi	sp,sp,64
    8000350a:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    8000350c:	04000613          	li	a2,64
    80003510:	4581                	li	a1,0
    80003512:	854e                	mv	a0,s3
    80003514:	ffffd097          	auipc	ra,0xffffd
    80003518:	7b8080e7          	jalr	1976(ra) # 80000ccc <memset>
      dip->type = type;
    8000351c:	01699023          	sh	s6,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003520:	8526                	mv	a0,s1
    80003522:	00001097          	auipc	ra,0x1
    80003526:	c66080e7          	jalr	-922(ra) # 80004188 <log_write>
      brelse(bp);
    8000352a:	8526                	mv	a0,s1
    8000352c:	00000097          	auipc	ra,0x0
    80003530:	a04080e7          	jalr	-1532(ra) # 80002f30 <brelse>
      return iget(dev, inum);
    80003534:	0009059b          	sext.w	a1,s2
    80003538:	8556                	mv	a0,s5
    8000353a:	00000097          	auipc	ra,0x0
    8000353e:	da2080e7          	jalr	-606(ra) # 800032dc <iget>
    80003542:	bf5d                	j	800034f8 <ialloc+0x80>

0000000080003544 <iupdate>:
{
    80003544:	1101                	addi	sp,sp,-32
    80003546:	ec06                	sd	ra,24(sp)
    80003548:	e822                	sd	s0,16(sp)
    8000354a:	e426                	sd	s1,8(sp)
    8000354c:	e04a                	sd	s2,0(sp)
    8000354e:	1000                	addi	s0,sp,32
    80003550:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003552:	415c                	lw	a5,4(a0)
    80003554:	0047d79b          	srliw	a5,a5,0x4
    80003558:	0001c597          	auipc	a1,0x1c
    8000355c:	b185a583          	lw	a1,-1256(a1) # 8001f070 <sb+0x18>
    80003560:	9dbd                	addw	a1,a1,a5
    80003562:	4108                	lw	a0,0(a0)
    80003564:	00000097          	auipc	ra,0x0
    80003568:	89c080e7          	jalr	-1892(ra) # 80002e00 <bread>
    8000356c:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000356e:	05850793          	addi	a5,a0,88
    80003572:	40d8                	lw	a4,4(s1)
    80003574:	8b3d                	andi	a4,a4,15
    80003576:	071a                	slli	a4,a4,0x6
    80003578:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    8000357a:	04449703          	lh	a4,68(s1)
    8000357e:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    80003582:	04649703          	lh	a4,70(s1)
    80003586:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    8000358a:	04849703          	lh	a4,72(s1)
    8000358e:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    80003592:	04a49703          	lh	a4,74(s1)
    80003596:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    8000359a:	44f8                	lw	a4,76(s1)
    8000359c:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    8000359e:	03400613          	li	a2,52
    800035a2:	05048593          	addi	a1,s1,80
    800035a6:	00c78513          	addi	a0,a5,12
    800035aa:	ffffd097          	auipc	ra,0xffffd
    800035ae:	77e080e7          	jalr	1918(ra) # 80000d28 <memmove>
  log_write(bp);
    800035b2:	854a                	mv	a0,s2
    800035b4:	00001097          	auipc	ra,0x1
    800035b8:	bd4080e7          	jalr	-1068(ra) # 80004188 <log_write>
  brelse(bp);
    800035bc:	854a                	mv	a0,s2
    800035be:	00000097          	auipc	ra,0x0
    800035c2:	972080e7          	jalr	-1678(ra) # 80002f30 <brelse>
}
    800035c6:	60e2                	ld	ra,24(sp)
    800035c8:	6442                	ld	s0,16(sp)
    800035ca:	64a2                	ld	s1,8(sp)
    800035cc:	6902                	ld	s2,0(sp)
    800035ce:	6105                	addi	sp,sp,32
    800035d0:	8082                	ret

00000000800035d2 <idup>:
{
    800035d2:	1101                	addi	sp,sp,-32
    800035d4:	ec06                	sd	ra,24(sp)
    800035d6:	e822                	sd	s0,16(sp)
    800035d8:	e426                	sd	s1,8(sp)
    800035da:	1000                	addi	s0,sp,32
    800035dc:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800035de:	0001c517          	auipc	a0,0x1c
    800035e2:	a9a50513          	addi	a0,a0,-1382 # 8001f078 <itable>
    800035e6:	ffffd097          	auipc	ra,0xffffd
    800035ea:	5ea080e7          	jalr	1514(ra) # 80000bd0 <acquire>
  ip->ref++;
    800035ee:	449c                	lw	a5,8(s1)
    800035f0:	2785                	addiw	a5,a5,1
    800035f2:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800035f4:	0001c517          	auipc	a0,0x1c
    800035f8:	a8450513          	addi	a0,a0,-1404 # 8001f078 <itable>
    800035fc:	ffffd097          	auipc	ra,0xffffd
    80003600:	688080e7          	jalr	1672(ra) # 80000c84 <release>
}
    80003604:	8526                	mv	a0,s1
    80003606:	60e2                	ld	ra,24(sp)
    80003608:	6442                	ld	s0,16(sp)
    8000360a:	64a2                	ld	s1,8(sp)
    8000360c:	6105                	addi	sp,sp,32
    8000360e:	8082                	ret

0000000080003610 <ilock>:
{
    80003610:	1101                	addi	sp,sp,-32
    80003612:	ec06                	sd	ra,24(sp)
    80003614:	e822                	sd	s0,16(sp)
    80003616:	e426                	sd	s1,8(sp)
    80003618:	e04a                	sd	s2,0(sp)
    8000361a:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    8000361c:	c115                	beqz	a0,80003640 <ilock+0x30>
    8000361e:	84aa                	mv	s1,a0
    80003620:	451c                	lw	a5,8(a0)
    80003622:	00f05f63          	blez	a5,80003640 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003626:	0541                	addi	a0,a0,16
    80003628:	00001097          	auipc	ra,0x1
    8000362c:	c7e080e7          	jalr	-898(ra) # 800042a6 <acquiresleep>
  if(ip->valid == 0){
    80003630:	40bc                	lw	a5,64(s1)
    80003632:	cf99                	beqz	a5,80003650 <ilock+0x40>
}
    80003634:	60e2                	ld	ra,24(sp)
    80003636:	6442                	ld	s0,16(sp)
    80003638:	64a2                	ld	s1,8(sp)
    8000363a:	6902                	ld	s2,0(sp)
    8000363c:	6105                	addi	sp,sp,32
    8000363e:	8082                	ret
    panic("ilock");
    80003640:	00005517          	auipc	a0,0x5
    80003644:	fb050513          	addi	a0,a0,-80 # 800085f0 <syscalls+0x180>
    80003648:	ffffd097          	auipc	ra,0xffffd
    8000364c:	ef2080e7          	jalr	-270(ra) # 8000053a <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003650:	40dc                	lw	a5,4(s1)
    80003652:	0047d79b          	srliw	a5,a5,0x4
    80003656:	0001c597          	auipc	a1,0x1c
    8000365a:	a1a5a583          	lw	a1,-1510(a1) # 8001f070 <sb+0x18>
    8000365e:	9dbd                	addw	a1,a1,a5
    80003660:	4088                	lw	a0,0(s1)
    80003662:	fffff097          	auipc	ra,0xfffff
    80003666:	79e080e7          	jalr	1950(ra) # 80002e00 <bread>
    8000366a:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000366c:	05850593          	addi	a1,a0,88
    80003670:	40dc                	lw	a5,4(s1)
    80003672:	8bbd                	andi	a5,a5,15
    80003674:	079a                	slli	a5,a5,0x6
    80003676:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003678:	00059783          	lh	a5,0(a1)
    8000367c:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003680:	00259783          	lh	a5,2(a1)
    80003684:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003688:	00459783          	lh	a5,4(a1)
    8000368c:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003690:	00659783          	lh	a5,6(a1)
    80003694:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003698:	459c                	lw	a5,8(a1)
    8000369a:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    8000369c:	03400613          	li	a2,52
    800036a0:	05b1                	addi	a1,a1,12
    800036a2:	05048513          	addi	a0,s1,80
    800036a6:	ffffd097          	auipc	ra,0xffffd
    800036aa:	682080e7          	jalr	1666(ra) # 80000d28 <memmove>
    brelse(bp);
    800036ae:	854a                	mv	a0,s2
    800036b0:	00000097          	auipc	ra,0x0
    800036b4:	880080e7          	jalr	-1920(ra) # 80002f30 <brelse>
    ip->valid = 1;
    800036b8:	4785                	li	a5,1
    800036ba:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800036bc:	04449783          	lh	a5,68(s1)
    800036c0:	fbb5                	bnez	a5,80003634 <ilock+0x24>
      panic("ilock: no type");
    800036c2:	00005517          	auipc	a0,0x5
    800036c6:	f3650513          	addi	a0,a0,-202 # 800085f8 <syscalls+0x188>
    800036ca:	ffffd097          	auipc	ra,0xffffd
    800036ce:	e70080e7          	jalr	-400(ra) # 8000053a <panic>

00000000800036d2 <iunlock>:
{
    800036d2:	1101                	addi	sp,sp,-32
    800036d4:	ec06                	sd	ra,24(sp)
    800036d6:	e822                	sd	s0,16(sp)
    800036d8:	e426                	sd	s1,8(sp)
    800036da:	e04a                	sd	s2,0(sp)
    800036dc:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    800036de:	c905                	beqz	a0,8000370e <iunlock+0x3c>
    800036e0:	84aa                	mv	s1,a0
    800036e2:	01050913          	addi	s2,a0,16
    800036e6:	854a                	mv	a0,s2
    800036e8:	00001097          	auipc	ra,0x1
    800036ec:	c58080e7          	jalr	-936(ra) # 80004340 <holdingsleep>
    800036f0:	cd19                	beqz	a0,8000370e <iunlock+0x3c>
    800036f2:	449c                	lw	a5,8(s1)
    800036f4:	00f05d63          	blez	a5,8000370e <iunlock+0x3c>
  releasesleep(&ip->lock);
    800036f8:	854a                	mv	a0,s2
    800036fa:	00001097          	auipc	ra,0x1
    800036fe:	c02080e7          	jalr	-1022(ra) # 800042fc <releasesleep>
}
    80003702:	60e2                	ld	ra,24(sp)
    80003704:	6442                	ld	s0,16(sp)
    80003706:	64a2                	ld	s1,8(sp)
    80003708:	6902                	ld	s2,0(sp)
    8000370a:	6105                	addi	sp,sp,32
    8000370c:	8082                	ret
    panic("iunlock");
    8000370e:	00005517          	auipc	a0,0x5
    80003712:	efa50513          	addi	a0,a0,-262 # 80008608 <syscalls+0x198>
    80003716:	ffffd097          	auipc	ra,0xffffd
    8000371a:	e24080e7          	jalr	-476(ra) # 8000053a <panic>

000000008000371e <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    8000371e:	7179                	addi	sp,sp,-48
    80003720:	f406                	sd	ra,40(sp)
    80003722:	f022                	sd	s0,32(sp)
    80003724:	ec26                	sd	s1,24(sp)
    80003726:	e84a                	sd	s2,16(sp)
    80003728:	e44e                	sd	s3,8(sp)
    8000372a:	e052                	sd	s4,0(sp)
    8000372c:	1800                	addi	s0,sp,48
    8000372e:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003730:	05050493          	addi	s1,a0,80
    80003734:	08050913          	addi	s2,a0,128
    80003738:	a021                	j	80003740 <itrunc+0x22>
    8000373a:	0491                	addi	s1,s1,4
    8000373c:	01248d63          	beq	s1,s2,80003756 <itrunc+0x38>
    if(ip->addrs[i]){
    80003740:	408c                	lw	a1,0(s1)
    80003742:	dde5                	beqz	a1,8000373a <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003744:	0009a503          	lw	a0,0(s3)
    80003748:	00000097          	auipc	ra,0x0
    8000374c:	8fc080e7          	jalr	-1796(ra) # 80003044 <bfree>
      ip->addrs[i] = 0;
    80003750:	0004a023          	sw	zero,0(s1)
    80003754:	b7dd                	j	8000373a <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003756:	0809a583          	lw	a1,128(s3)
    8000375a:	e185                	bnez	a1,8000377a <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    8000375c:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003760:	854e                	mv	a0,s3
    80003762:	00000097          	auipc	ra,0x0
    80003766:	de2080e7          	jalr	-542(ra) # 80003544 <iupdate>
}
    8000376a:	70a2                	ld	ra,40(sp)
    8000376c:	7402                	ld	s0,32(sp)
    8000376e:	64e2                	ld	s1,24(sp)
    80003770:	6942                	ld	s2,16(sp)
    80003772:	69a2                	ld	s3,8(sp)
    80003774:	6a02                	ld	s4,0(sp)
    80003776:	6145                	addi	sp,sp,48
    80003778:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    8000377a:	0009a503          	lw	a0,0(s3)
    8000377e:	fffff097          	auipc	ra,0xfffff
    80003782:	682080e7          	jalr	1666(ra) # 80002e00 <bread>
    80003786:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003788:	05850493          	addi	s1,a0,88
    8000378c:	45850913          	addi	s2,a0,1112
    80003790:	a021                	j	80003798 <itrunc+0x7a>
    80003792:	0491                	addi	s1,s1,4
    80003794:	01248b63          	beq	s1,s2,800037aa <itrunc+0x8c>
      if(a[j])
    80003798:	408c                	lw	a1,0(s1)
    8000379a:	dde5                	beqz	a1,80003792 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    8000379c:	0009a503          	lw	a0,0(s3)
    800037a0:	00000097          	auipc	ra,0x0
    800037a4:	8a4080e7          	jalr	-1884(ra) # 80003044 <bfree>
    800037a8:	b7ed                	j	80003792 <itrunc+0x74>
    brelse(bp);
    800037aa:	8552                	mv	a0,s4
    800037ac:	fffff097          	auipc	ra,0xfffff
    800037b0:	784080e7          	jalr	1924(ra) # 80002f30 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    800037b4:	0809a583          	lw	a1,128(s3)
    800037b8:	0009a503          	lw	a0,0(s3)
    800037bc:	00000097          	auipc	ra,0x0
    800037c0:	888080e7          	jalr	-1912(ra) # 80003044 <bfree>
    ip->addrs[NDIRECT] = 0;
    800037c4:	0809a023          	sw	zero,128(s3)
    800037c8:	bf51                	j	8000375c <itrunc+0x3e>

00000000800037ca <iput>:
{
    800037ca:	1101                	addi	sp,sp,-32
    800037cc:	ec06                	sd	ra,24(sp)
    800037ce:	e822                	sd	s0,16(sp)
    800037d0:	e426                	sd	s1,8(sp)
    800037d2:	e04a                	sd	s2,0(sp)
    800037d4:	1000                	addi	s0,sp,32
    800037d6:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800037d8:	0001c517          	auipc	a0,0x1c
    800037dc:	8a050513          	addi	a0,a0,-1888 # 8001f078 <itable>
    800037e0:	ffffd097          	auipc	ra,0xffffd
    800037e4:	3f0080e7          	jalr	1008(ra) # 80000bd0 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800037e8:	4498                	lw	a4,8(s1)
    800037ea:	4785                	li	a5,1
    800037ec:	02f70363          	beq	a4,a5,80003812 <iput+0x48>
  ip->ref--;
    800037f0:	449c                	lw	a5,8(s1)
    800037f2:	37fd                	addiw	a5,a5,-1
    800037f4:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800037f6:	0001c517          	auipc	a0,0x1c
    800037fa:	88250513          	addi	a0,a0,-1918 # 8001f078 <itable>
    800037fe:	ffffd097          	auipc	ra,0xffffd
    80003802:	486080e7          	jalr	1158(ra) # 80000c84 <release>
}
    80003806:	60e2                	ld	ra,24(sp)
    80003808:	6442                	ld	s0,16(sp)
    8000380a:	64a2                	ld	s1,8(sp)
    8000380c:	6902                	ld	s2,0(sp)
    8000380e:	6105                	addi	sp,sp,32
    80003810:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003812:	40bc                	lw	a5,64(s1)
    80003814:	dff1                	beqz	a5,800037f0 <iput+0x26>
    80003816:	04a49783          	lh	a5,74(s1)
    8000381a:	fbf9                	bnez	a5,800037f0 <iput+0x26>
    acquiresleep(&ip->lock);
    8000381c:	01048913          	addi	s2,s1,16
    80003820:	854a                	mv	a0,s2
    80003822:	00001097          	auipc	ra,0x1
    80003826:	a84080e7          	jalr	-1404(ra) # 800042a6 <acquiresleep>
    release(&itable.lock);
    8000382a:	0001c517          	auipc	a0,0x1c
    8000382e:	84e50513          	addi	a0,a0,-1970 # 8001f078 <itable>
    80003832:	ffffd097          	auipc	ra,0xffffd
    80003836:	452080e7          	jalr	1106(ra) # 80000c84 <release>
    itrunc(ip);
    8000383a:	8526                	mv	a0,s1
    8000383c:	00000097          	auipc	ra,0x0
    80003840:	ee2080e7          	jalr	-286(ra) # 8000371e <itrunc>
    ip->type = 0;
    80003844:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003848:	8526                	mv	a0,s1
    8000384a:	00000097          	auipc	ra,0x0
    8000384e:	cfa080e7          	jalr	-774(ra) # 80003544 <iupdate>
    ip->valid = 0;
    80003852:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003856:	854a                	mv	a0,s2
    80003858:	00001097          	auipc	ra,0x1
    8000385c:	aa4080e7          	jalr	-1372(ra) # 800042fc <releasesleep>
    acquire(&itable.lock);
    80003860:	0001c517          	auipc	a0,0x1c
    80003864:	81850513          	addi	a0,a0,-2024 # 8001f078 <itable>
    80003868:	ffffd097          	auipc	ra,0xffffd
    8000386c:	368080e7          	jalr	872(ra) # 80000bd0 <acquire>
    80003870:	b741                	j	800037f0 <iput+0x26>

0000000080003872 <iunlockput>:
{
    80003872:	1101                	addi	sp,sp,-32
    80003874:	ec06                	sd	ra,24(sp)
    80003876:	e822                	sd	s0,16(sp)
    80003878:	e426                	sd	s1,8(sp)
    8000387a:	1000                	addi	s0,sp,32
    8000387c:	84aa                	mv	s1,a0
  iunlock(ip);
    8000387e:	00000097          	auipc	ra,0x0
    80003882:	e54080e7          	jalr	-428(ra) # 800036d2 <iunlock>
  iput(ip);
    80003886:	8526                	mv	a0,s1
    80003888:	00000097          	auipc	ra,0x0
    8000388c:	f42080e7          	jalr	-190(ra) # 800037ca <iput>
}
    80003890:	60e2                	ld	ra,24(sp)
    80003892:	6442                	ld	s0,16(sp)
    80003894:	64a2                	ld	s1,8(sp)
    80003896:	6105                	addi	sp,sp,32
    80003898:	8082                	ret

000000008000389a <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    8000389a:	1141                	addi	sp,sp,-16
    8000389c:	e422                	sd	s0,8(sp)
    8000389e:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    800038a0:	411c                	lw	a5,0(a0)
    800038a2:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    800038a4:	415c                	lw	a5,4(a0)
    800038a6:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    800038a8:	04451783          	lh	a5,68(a0)
    800038ac:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    800038b0:	04a51783          	lh	a5,74(a0)
    800038b4:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    800038b8:	04c56783          	lwu	a5,76(a0)
    800038bc:	e99c                	sd	a5,16(a1)
}
    800038be:	6422                	ld	s0,8(sp)
    800038c0:	0141                	addi	sp,sp,16
    800038c2:	8082                	ret

00000000800038c4 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800038c4:	457c                	lw	a5,76(a0)
    800038c6:	0ed7e963          	bltu	a5,a3,800039b8 <readi+0xf4>
{
    800038ca:	7159                	addi	sp,sp,-112
    800038cc:	f486                	sd	ra,104(sp)
    800038ce:	f0a2                	sd	s0,96(sp)
    800038d0:	eca6                	sd	s1,88(sp)
    800038d2:	e8ca                	sd	s2,80(sp)
    800038d4:	e4ce                	sd	s3,72(sp)
    800038d6:	e0d2                	sd	s4,64(sp)
    800038d8:	fc56                	sd	s5,56(sp)
    800038da:	f85a                	sd	s6,48(sp)
    800038dc:	f45e                	sd	s7,40(sp)
    800038de:	f062                	sd	s8,32(sp)
    800038e0:	ec66                	sd	s9,24(sp)
    800038e2:	e86a                	sd	s10,16(sp)
    800038e4:	e46e                	sd	s11,8(sp)
    800038e6:	1880                	addi	s0,sp,112
    800038e8:	8b2a                	mv	s6,a0
    800038ea:	8bae                	mv	s7,a1
    800038ec:	8a32                	mv	s4,a2
    800038ee:	84b6                	mv	s1,a3
    800038f0:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    800038f2:	9f35                	addw	a4,a4,a3
    return 0;
    800038f4:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    800038f6:	0ad76063          	bltu	a4,a3,80003996 <readi+0xd2>
  if(off + n > ip->size)
    800038fa:	00e7f463          	bgeu	a5,a4,80003902 <readi+0x3e>
    n = ip->size - off;
    800038fe:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003902:	0a0a8963          	beqz	s5,800039b4 <readi+0xf0>
    80003906:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003908:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    8000390c:	5c7d                	li	s8,-1
    8000390e:	a82d                	j	80003948 <readi+0x84>
    80003910:	020d1d93          	slli	s11,s10,0x20
    80003914:	020ddd93          	srli	s11,s11,0x20
    80003918:	05890613          	addi	a2,s2,88
    8000391c:	86ee                	mv	a3,s11
    8000391e:	963a                	add	a2,a2,a4
    80003920:	85d2                	mv	a1,s4
    80003922:	855e                	mv	a0,s7
    80003924:	fffff097          	auipc	ra,0xfffff
    80003928:	b20080e7          	jalr	-1248(ra) # 80002444 <either_copyout>
    8000392c:	05850d63          	beq	a0,s8,80003986 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003930:	854a                	mv	a0,s2
    80003932:	fffff097          	auipc	ra,0xfffff
    80003936:	5fe080e7          	jalr	1534(ra) # 80002f30 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000393a:	013d09bb          	addw	s3,s10,s3
    8000393e:	009d04bb          	addw	s1,s10,s1
    80003942:	9a6e                	add	s4,s4,s11
    80003944:	0559f763          	bgeu	s3,s5,80003992 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003948:	00a4d59b          	srliw	a1,s1,0xa
    8000394c:	855a                	mv	a0,s6
    8000394e:	00000097          	auipc	ra,0x0
    80003952:	8a4080e7          	jalr	-1884(ra) # 800031f2 <bmap>
    80003956:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    8000395a:	cd85                	beqz	a1,80003992 <readi+0xce>
    bp = bread(ip->dev, addr);
    8000395c:	000b2503          	lw	a0,0(s6)
    80003960:	fffff097          	auipc	ra,0xfffff
    80003964:	4a0080e7          	jalr	1184(ra) # 80002e00 <bread>
    80003968:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    8000396a:	3ff4f713          	andi	a4,s1,1023
    8000396e:	40ec87bb          	subw	a5,s9,a4
    80003972:	413a86bb          	subw	a3,s5,s3
    80003976:	8d3e                	mv	s10,a5
    80003978:	2781                	sext.w	a5,a5
    8000397a:	0006861b          	sext.w	a2,a3
    8000397e:	f8f679e3          	bgeu	a2,a5,80003910 <readi+0x4c>
    80003982:	8d36                	mv	s10,a3
    80003984:	b771                	j	80003910 <readi+0x4c>
      brelse(bp);
    80003986:	854a                	mv	a0,s2
    80003988:	fffff097          	auipc	ra,0xfffff
    8000398c:	5a8080e7          	jalr	1448(ra) # 80002f30 <brelse>
      tot = -1;
    80003990:	59fd                	li	s3,-1
  }
  return tot;
    80003992:	0009851b          	sext.w	a0,s3
}
    80003996:	70a6                	ld	ra,104(sp)
    80003998:	7406                	ld	s0,96(sp)
    8000399a:	64e6                	ld	s1,88(sp)
    8000399c:	6946                	ld	s2,80(sp)
    8000399e:	69a6                	ld	s3,72(sp)
    800039a0:	6a06                	ld	s4,64(sp)
    800039a2:	7ae2                	ld	s5,56(sp)
    800039a4:	7b42                	ld	s6,48(sp)
    800039a6:	7ba2                	ld	s7,40(sp)
    800039a8:	7c02                	ld	s8,32(sp)
    800039aa:	6ce2                	ld	s9,24(sp)
    800039ac:	6d42                	ld	s10,16(sp)
    800039ae:	6da2                	ld	s11,8(sp)
    800039b0:	6165                	addi	sp,sp,112
    800039b2:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800039b4:	89d6                	mv	s3,s5
    800039b6:	bff1                	j	80003992 <readi+0xce>
    return 0;
    800039b8:	4501                	li	a0,0
}
    800039ba:	8082                	ret

00000000800039bc <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800039bc:	457c                	lw	a5,76(a0)
    800039be:	10d7e863          	bltu	a5,a3,80003ace <writei+0x112>
{
    800039c2:	7159                	addi	sp,sp,-112
    800039c4:	f486                	sd	ra,104(sp)
    800039c6:	f0a2                	sd	s0,96(sp)
    800039c8:	eca6                	sd	s1,88(sp)
    800039ca:	e8ca                	sd	s2,80(sp)
    800039cc:	e4ce                	sd	s3,72(sp)
    800039ce:	e0d2                	sd	s4,64(sp)
    800039d0:	fc56                	sd	s5,56(sp)
    800039d2:	f85a                	sd	s6,48(sp)
    800039d4:	f45e                	sd	s7,40(sp)
    800039d6:	f062                	sd	s8,32(sp)
    800039d8:	ec66                	sd	s9,24(sp)
    800039da:	e86a                	sd	s10,16(sp)
    800039dc:	e46e                	sd	s11,8(sp)
    800039de:	1880                	addi	s0,sp,112
    800039e0:	8aaa                	mv	s5,a0
    800039e2:	8bae                	mv	s7,a1
    800039e4:	8a32                	mv	s4,a2
    800039e6:	8936                	mv	s2,a3
    800039e8:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    800039ea:	00e687bb          	addw	a5,a3,a4
    800039ee:	0ed7e263          	bltu	a5,a3,80003ad2 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    800039f2:	00043737          	lui	a4,0x43
    800039f6:	0ef76063          	bltu	a4,a5,80003ad6 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800039fa:	0c0b0863          	beqz	s6,80003aca <writei+0x10e>
    800039fe:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a00:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003a04:	5c7d                	li	s8,-1
    80003a06:	a091                	j	80003a4a <writei+0x8e>
    80003a08:	020d1d93          	slli	s11,s10,0x20
    80003a0c:	020ddd93          	srli	s11,s11,0x20
    80003a10:	05848513          	addi	a0,s1,88
    80003a14:	86ee                	mv	a3,s11
    80003a16:	8652                	mv	a2,s4
    80003a18:	85de                	mv	a1,s7
    80003a1a:	953a                	add	a0,a0,a4
    80003a1c:	fffff097          	auipc	ra,0xfffff
    80003a20:	a7e080e7          	jalr	-1410(ra) # 8000249a <either_copyin>
    80003a24:	07850263          	beq	a0,s8,80003a88 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003a28:	8526                	mv	a0,s1
    80003a2a:	00000097          	auipc	ra,0x0
    80003a2e:	75e080e7          	jalr	1886(ra) # 80004188 <log_write>
    brelse(bp);
    80003a32:	8526                	mv	a0,s1
    80003a34:	fffff097          	auipc	ra,0xfffff
    80003a38:	4fc080e7          	jalr	1276(ra) # 80002f30 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003a3c:	013d09bb          	addw	s3,s10,s3
    80003a40:	012d093b          	addw	s2,s10,s2
    80003a44:	9a6e                	add	s4,s4,s11
    80003a46:	0569f663          	bgeu	s3,s6,80003a92 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003a4a:	00a9559b          	srliw	a1,s2,0xa
    80003a4e:	8556                	mv	a0,s5
    80003a50:	fffff097          	auipc	ra,0xfffff
    80003a54:	7a2080e7          	jalr	1954(ra) # 800031f2 <bmap>
    80003a58:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003a5c:	c99d                	beqz	a1,80003a92 <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003a5e:	000aa503          	lw	a0,0(s5)
    80003a62:	fffff097          	auipc	ra,0xfffff
    80003a66:	39e080e7          	jalr	926(ra) # 80002e00 <bread>
    80003a6a:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a6c:	3ff97713          	andi	a4,s2,1023
    80003a70:	40ec87bb          	subw	a5,s9,a4
    80003a74:	413b06bb          	subw	a3,s6,s3
    80003a78:	8d3e                	mv	s10,a5
    80003a7a:	2781                	sext.w	a5,a5
    80003a7c:	0006861b          	sext.w	a2,a3
    80003a80:	f8f674e3          	bgeu	a2,a5,80003a08 <writei+0x4c>
    80003a84:	8d36                	mv	s10,a3
    80003a86:	b749                	j	80003a08 <writei+0x4c>
      brelse(bp);
    80003a88:	8526                	mv	a0,s1
    80003a8a:	fffff097          	auipc	ra,0xfffff
    80003a8e:	4a6080e7          	jalr	1190(ra) # 80002f30 <brelse>
  }

  if(off > ip->size)
    80003a92:	04caa783          	lw	a5,76(s5)
    80003a96:	0127f463          	bgeu	a5,s2,80003a9e <writei+0xe2>
    ip->size = off;
    80003a9a:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003a9e:	8556                	mv	a0,s5
    80003aa0:	00000097          	auipc	ra,0x0
    80003aa4:	aa4080e7          	jalr	-1372(ra) # 80003544 <iupdate>

  return tot;
    80003aa8:	0009851b          	sext.w	a0,s3
}
    80003aac:	70a6                	ld	ra,104(sp)
    80003aae:	7406                	ld	s0,96(sp)
    80003ab0:	64e6                	ld	s1,88(sp)
    80003ab2:	6946                	ld	s2,80(sp)
    80003ab4:	69a6                	ld	s3,72(sp)
    80003ab6:	6a06                	ld	s4,64(sp)
    80003ab8:	7ae2                	ld	s5,56(sp)
    80003aba:	7b42                	ld	s6,48(sp)
    80003abc:	7ba2                	ld	s7,40(sp)
    80003abe:	7c02                	ld	s8,32(sp)
    80003ac0:	6ce2                	ld	s9,24(sp)
    80003ac2:	6d42                	ld	s10,16(sp)
    80003ac4:	6da2                	ld	s11,8(sp)
    80003ac6:	6165                	addi	sp,sp,112
    80003ac8:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003aca:	89da                	mv	s3,s6
    80003acc:	bfc9                	j	80003a9e <writei+0xe2>
    return -1;
    80003ace:	557d                	li	a0,-1
}
    80003ad0:	8082                	ret
    return -1;
    80003ad2:	557d                	li	a0,-1
    80003ad4:	bfe1                	j	80003aac <writei+0xf0>
    return -1;
    80003ad6:	557d                	li	a0,-1
    80003ad8:	bfd1                	j	80003aac <writei+0xf0>

0000000080003ada <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003ada:	1141                	addi	sp,sp,-16
    80003adc:	e406                	sd	ra,8(sp)
    80003ade:	e022                	sd	s0,0(sp)
    80003ae0:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003ae2:	4639                	li	a2,14
    80003ae4:	ffffd097          	auipc	ra,0xffffd
    80003ae8:	2b8080e7          	jalr	696(ra) # 80000d9c <strncmp>
}
    80003aec:	60a2                	ld	ra,8(sp)
    80003aee:	6402                	ld	s0,0(sp)
    80003af0:	0141                	addi	sp,sp,16
    80003af2:	8082                	ret

0000000080003af4 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003af4:	7139                	addi	sp,sp,-64
    80003af6:	fc06                	sd	ra,56(sp)
    80003af8:	f822                	sd	s0,48(sp)
    80003afa:	f426                	sd	s1,40(sp)
    80003afc:	f04a                	sd	s2,32(sp)
    80003afe:	ec4e                	sd	s3,24(sp)
    80003b00:	e852                	sd	s4,16(sp)
    80003b02:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003b04:	04451703          	lh	a4,68(a0)
    80003b08:	4785                	li	a5,1
    80003b0a:	00f71a63          	bne	a4,a5,80003b1e <dirlookup+0x2a>
    80003b0e:	892a                	mv	s2,a0
    80003b10:	89ae                	mv	s3,a1
    80003b12:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003b14:	457c                	lw	a5,76(a0)
    80003b16:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003b18:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003b1a:	e79d                	bnez	a5,80003b48 <dirlookup+0x54>
    80003b1c:	a8a5                	j	80003b94 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003b1e:	00005517          	auipc	a0,0x5
    80003b22:	af250513          	addi	a0,a0,-1294 # 80008610 <syscalls+0x1a0>
    80003b26:	ffffd097          	auipc	ra,0xffffd
    80003b2a:	a14080e7          	jalr	-1516(ra) # 8000053a <panic>
      panic("dirlookup read");
    80003b2e:	00005517          	auipc	a0,0x5
    80003b32:	afa50513          	addi	a0,a0,-1286 # 80008628 <syscalls+0x1b8>
    80003b36:	ffffd097          	auipc	ra,0xffffd
    80003b3a:	a04080e7          	jalr	-1532(ra) # 8000053a <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003b3e:	24c1                	addiw	s1,s1,16
    80003b40:	04c92783          	lw	a5,76(s2)
    80003b44:	04f4f763          	bgeu	s1,a5,80003b92 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003b48:	4741                	li	a4,16
    80003b4a:	86a6                	mv	a3,s1
    80003b4c:	fc040613          	addi	a2,s0,-64
    80003b50:	4581                	li	a1,0
    80003b52:	854a                	mv	a0,s2
    80003b54:	00000097          	auipc	ra,0x0
    80003b58:	d70080e7          	jalr	-656(ra) # 800038c4 <readi>
    80003b5c:	47c1                	li	a5,16
    80003b5e:	fcf518e3          	bne	a0,a5,80003b2e <dirlookup+0x3a>
    if(de.inum == 0)
    80003b62:	fc045783          	lhu	a5,-64(s0)
    80003b66:	dfe1                	beqz	a5,80003b3e <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003b68:	fc240593          	addi	a1,s0,-62
    80003b6c:	854e                	mv	a0,s3
    80003b6e:	00000097          	auipc	ra,0x0
    80003b72:	f6c080e7          	jalr	-148(ra) # 80003ada <namecmp>
    80003b76:	f561                	bnez	a0,80003b3e <dirlookup+0x4a>
      if(poff)
    80003b78:	000a0463          	beqz	s4,80003b80 <dirlookup+0x8c>
        *poff = off;
    80003b7c:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003b80:	fc045583          	lhu	a1,-64(s0)
    80003b84:	00092503          	lw	a0,0(s2)
    80003b88:	fffff097          	auipc	ra,0xfffff
    80003b8c:	754080e7          	jalr	1876(ra) # 800032dc <iget>
    80003b90:	a011                	j	80003b94 <dirlookup+0xa0>
  return 0;
    80003b92:	4501                	li	a0,0
}
    80003b94:	70e2                	ld	ra,56(sp)
    80003b96:	7442                	ld	s0,48(sp)
    80003b98:	74a2                	ld	s1,40(sp)
    80003b9a:	7902                	ld	s2,32(sp)
    80003b9c:	69e2                	ld	s3,24(sp)
    80003b9e:	6a42                	ld	s4,16(sp)
    80003ba0:	6121                	addi	sp,sp,64
    80003ba2:	8082                	ret

0000000080003ba4 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003ba4:	711d                	addi	sp,sp,-96
    80003ba6:	ec86                	sd	ra,88(sp)
    80003ba8:	e8a2                	sd	s0,80(sp)
    80003baa:	e4a6                	sd	s1,72(sp)
    80003bac:	e0ca                	sd	s2,64(sp)
    80003bae:	fc4e                	sd	s3,56(sp)
    80003bb0:	f852                	sd	s4,48(sp)
    80003bb2:	f456                	sd	s5,40(sp)
    80003bb4:	f05a                	sd	s6,32(sp)
    80003bb6:	ec5e                	sd	s7,24(sp)
    80003bb8:	e862                	sd	s8,16(sp)
    80003bba:	e466                	sd	s9,8(sp)
    80003bbc:	1080                	addi	s0,sp,96
    80003bbe:	84aa                	mv	s1,a0
    80003bc0:	8b2e                	mv	s6,a1
    80003bc2:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003bc4:	00054703          	lbu	a4,0(a0)
    80003bc8:	02f00793          	li	a5,47
    80003bcc:	02f70263          	beq	a4,a5,80003bf0 <namex+0x4c>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003bd0:	ffffe097          	auipc	ra,0xffffe
    80003bd4:	dc4080e7          	jalr	-572(ra) # 80001994 <myproc>
    80003bd8:	15053503          	ld	a0,336(a0)
    80003bdc:	00000097          	auipc	ra,0x0
    80003be0:	9f6080e7          	jalr	-1546(ra) # 800035d2 <idup>
    80003be4:	8a2a                	mv	s4,a0
  while(*path == '/')
    80003be6:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    80003bea:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003bec:	4b85                	li	s7,1
    80003bee:	a875                	j	80003caa <namex+0x106>
    ip = iget(ROOTDEV, ROOTINO);
    80003bf0:	4585                	li	a1,1
    80003bf2:	4505                	li	a0,1
    80003bf4:	fffff097          	auipc	ra,0xfffff
    80003bf8:	6e8080e7          	jalr	1768(ra) # 800032dc <iget>
    80003bfc:	8a2a                	mv	s4,a0
    80003bfe:	b7e5                	j	80003be6 <namex+0x42>
      iunlockput(ip);
    80003c00:	8552                	mv	a0,s4
    80003c02:	00000097          	auipc	ra,0x0
    80003c06:	c70080e7          	jalr	-912(ra) # 80003872 <iunlockput>
      return 0;
    80003c0a:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003c0c:	8552                	mv	a0,s4
    80003c0e:	60e6                	ld	ra,88(sp)
    80003c10:	6446                	ld	s0,80(sp)
    80003c12:	64a6                	ld	s1,72(sp)
    80003c14:	6906                	ld	s2,64(sp)
    80003c16:	79e2                	ld	s3,56(sp)
    80003c18:	7a42                	ld	s4,48(sp)
    80003c1a:	7aa2                	ld	s5,40(sp)
    80003c1c:	7b02                	ld	s6,32(sp)
    80003c1e:	6be2                	ld	s7,24(sp)
    80003c20:	6c42                	ld	s8,16(sp)
    80003c22:	6ca2                	ld	s9,8(sp)
    80003c24:	6125                	addi	sp,sp,96
    80003c26:	8082                	ret
      iunlock(ip);
    80003c28:	8552                	mv	a0,s4
    80003c2a:	00000097          	auipc	ra,0x0
    80003c2e:	aa8080e7          	jalr	-1368(ra) # 800036d2 <iunlock>
      return ip;
    80003c32:	bfe9                	j	80003c0c <namex+0x68>
      iunlockput(ip);
    80003c34:	8552                	mv	a0,s4
    80003c36:	00000097          	auipc	ra,0x0
    80003c3a:	c3c080e7          	jalr	-964(ra) # 80003872 <iunlockput>
      return 0;
    80003c3e:	8a4e                	mv	s4,s3
    80003c40:	b7f1                	j	80003c0c <namex+0x68>
  len = path - s;
    80003c42:	40998633          	sub	a2,s3,s1
    80003c46:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80003c4a:	099c5863          	bge	s8,s9,80003cda <namex+0x136>
    memmove(name, s, DIRSIZ);
    80003c4e:	4639                	li	a2,14
    80003c50:	85a6                	mv	a1,s1
    80003c52:	8556                	mv	a0,s5
    80003c54:	ffffd097          	auipc	ra,0xffffd
    80003c58:	0d4080e7          	jalr	212(ra) # 80000d28 <memmove>
    80003c5c:	84ce                	mv	s1,s3
  while(*path == '/')
    80003c5e:	0004c783          	lbu	a5,0(s1)
    80003c62:	01279763          	bne	a5,s2,80003c70 <namex+0xcc>
    path++;
    80003c66:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003c68:	0004c783          	lbu	a5,0(s1)
    80003c6c:	ff278de3          	beq	a5,s2,80003c66 <namex+0xc2>
    ilock(ip);
    80003c70:	8552                	mv	a0,s4
    80003c72:	00000097          	auipc	ra,0x0
    80003c76:	99e080e7          	jalr	-1634(ra) # 80003610 <ilock>
    if(ip->type != T_DIR){
    80003c7a:	044a1783          	lh	a5,68(s4)
    80003c7e:	f97791e3          	bne	a5,s7,80003c00 <namex+0x5c>
    if(nameiparent && *path == '\0'){
    80003c82:	000b0563          	beqz	s6,80003c8c <namex+0xe8>
    80003c86:	0004c783          	lbu	a5,0(s1)
    80003c8a:	dfd9                	beqz	a5,80003c28 <namex+0x84>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003c8c:	4601                	li	a2,0
    80003c8e:	85d6                	mv	a1,s5
    80003c90:	8552                	mv	a0,s4
    80003c92:	00000097          	auipc	ra,0x0
    80003c96:	e62080e7          	jalr	-414(ra) # 80003af4 <dirlookup>
    80003c9a:	89aa                	mv	s3,a0
    80003c9c:	dd41                	beqz	a0,80003c34 <namex+0x90>
    iunlockput(ip);
    80003c9e:	8552                	mv	a0,s4
    80003ca0:	00000097          	auipc	ra,0x0
    80003ca4:	bd2080e7          	jalr	-1070(ra) # 80003872 <iunlockput>
    ip = next;
    80003ca8:	8a4e                	mv	s4,s3
  while(*path == '/')
    80003caa:	0004c783          	lbu	a5,0(s1)
    80003cae:	01279763          	bne	a5,s2,80003cbc <namex+0x118>
    path++;
    80003cb2:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003cb4:	0004c783          	lbu	a5,0(s1)
    80003cb8:	ff278de3          	beq	a5,s2,80003cb2 <namex+0x10e>
  if(*path == 0)
    80003cbc:	cb9d                	beqz	a5,80003cf2 <namex+0x14e>
  while(*path != '/' && *path != 0)
    80003cbe:	0004c783          	lbu	a5,0(s1)
    80003cc2:	89a6                	mv	s3,s1
  len = path - s;
    80003cc4:	4c81                	li	s9,0
    80003cc6:	4601                	li	a2,0
  while(*path != '/' && *path != 0)
    80003cc8:	01278963          	beq	a5,s2,80003cda <namex+0x136>
    80003ccc:	dbbd                	beqz	a5,80003c42 <namex+0x9e>
    path++;
    80003cce:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    80003cd0:	0009c783          	lbu	a5,0(s3)
    80003cd4:	ff279ce3          	bne	a5,s2,80003ccc <namex+0x128>
    80003cd8:	b7ad                	j	80003c42 <namex+0x9e>
    memmove(name, s, len);
    80003cda:	2601                	sext.w	a2,a2
    80003cdc:	85a6                	mv	a1,s1
    80003cde:	8556                	mv	a0,s5
    80003ce0:	ffffd097          	auipc	ra,0xffffd
    80003ce4:	048080e7          	jalr	72(ra) # 80000d28 <memmove>
    name[len] = 0;
    80003ce8:	9cd6                	add	s9,s9,s5
    80003cea:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80003cee:	84ce                	mv	s1,s3
    80003cf0:	b7bd                	j	80003c5e <namex+0xba>
  if(nameiparent){
    80003cf2:	f00b0de3          	beqz	s6,80003c0c <namex+0x68>
    iput(ip);
    80003cf6:	8552                	mv	a0,s4
    80003cf8:	00000097          	auipc	ra,0x0
    80003cfc:	ad2080e7          	jalr	-1326(ra) # 800037ca <iput>
    return 0;
    80003d00:	4a01                	li	s4,0
    80003d02:	b729                	j	80003c0c <namex+0x68>

0000000080003d04 <dirlink>:
{
    80003d04:	7139                	addi	sp,sp,-64
    80003d06:	fc06                	sd	ra,56(sp)
    80003d08:	f822                	sd	s0,48(sp)
    80003d0a:	f426                	sd	s1,40(sp)
    80003d0c:	f04a                	sd	s2,32(sp)
    80003d0e:	ec4e                	sd	s3,24(sp)
    80003d10:	e852                	sd	s4,16(sp)
    80003d12:	0080                	addi	s0,sp,64
    80003d14:	892a                	mv	s2,a0
    80003d16:	8a2e                	mv	s4,a1
    80003d18:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003d1a:	4601                	li	a2,0
    80003d1c:	00000097          	auipc	ra,0x0
    80003d20:	dd8080e7          	jalr	-552(ra) # 80003af4 <dirlookup>
    80003d24:	e93d                	bnez	a0,80003d9a <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d26:	04c92483          	lw	s1,76(s2)
    80003d2a:	c49d                	beqz	s1,80003d58 <dirlink+0x54>
    80003d2c:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003d2e:	4741                	li	a4,16
    80003d30:	86a6                	mv	a3,s1
    80003d32:	fc040613          	addi	a2,s0,-64
    80003d36:	4581                	li	a1,0
    80003d38:	854a                	mv	a0,s2
    80003d3a:	00000097          	auipc	ra,0x0
    80003d3e:	b8a080e7          	jalr	-1142(ra) # 800038c4 <readi>
    80003d42:	47c1                	li	a5,16
    80003d44:	06f51163          	bne	a0,a5,80003da6 <dirlink+0xa2>
    if(de.inum == 0)
    80003d48:	fc045783          	lhu	a5,-64(s0)
    80003d4c:	c791                	beqz	a5,80003d58 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d4e:	24c1                	addiw	s1,s1,16
    80003d50:	04c92783          	lw	a5,76(s2)
    80003d54:	fcf4ede3          	bltu	s1,a5,80003d2e <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003d58:	4639                	li	a2,14
    80003d5a:	85d2                	mv	a1,s4
    80003d5c:	fc240513          	addi	a0,s0,-62
    80003d60:	ffffd097          	auipc	ra,0xffffd
    80003d64:	078080e7          	jalr	120(ra) # 80000dd8 <strncpy>
  de.inum = inum;
    80003d68:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003d6c:	4741                	li	a4,16
    80003d6e:	86a6                	mv	a3,s1
    80003d70:	fc040613          	addi	a2,s0,-64
    80003d74:	4581                	li	a1,0
    80003d76:	854a                	mv	a0,s2
    80003d78:	00000097          	auipc	ra,0x0
    80003d7c:	c44080e7          	jalr	-956(ra) # 800039bc <writei>
    80003d80:	1541                	addi	a0,a0,-16
    80003d82:	00a03533          	snez	a0,a0
    80003d86:	40a00533          	neg	a0,a0
}
    80003d8a:	70e2                	ld	ra,56(sp)
    80003d8c:	7442                	ld	s0,48(sp)
    80003d8e:	74a2                	ld	s1,40(sp)
    80003d90:	7902                	ld	s2,32(sp)
    80003d92:	69e2                	ld	s3,24(sp)
    80003d94:	6a42                	ld	s4,16(sp)
    80003d96:	6121                	addi	sp,sp,64
    80003d98:	8082                	ret
    iput(ip);
    80003d9a:	00000097          	auipc	ra,0x0
    80003d9e:	a30080e7          	jalr	-1488(ra) # 800037ca <iput>
    return -1;
    80003da2:	557d                	li	a0,-1
    80003da4:	b7dd                	j	80003d8a <dirlink+0x86>
      panic("dirlink read");
    80003da6:	00005517          	auipc	a0,0x5
    80003daa:	89250513          	addi	a0,a0,-1902 # 80008638 <syscalls+0x1c8>
    80003dae:	ffffc097          	auipc	ra,0xffffc
    80003db2:	78c080e7          	jalr	1932(ra) # 8000053a <panic>

0000000080003db6 <namei>:

struct inode*
namei(char *path)
{
    80003db6:	1101                	addi	sp,sp,-32
    80003db8:	ec06                	sd	ra,24(sp)
    80003dba:	e822                	sd	s0,16(sp)
    80003dbc:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003dbe:	fe040613          	addi	a2,s0,-32
    80003dc2:	4581                	li	a1,0
    80003dc4:	00000097          	auipc	ra,0x0
    80003dc8:	de0080e7          	jalr	-544(ra) # 80003ba4 <namex>
}
    80003dcc:	60e2                	ld	ra,24(sp)
    80003dce:	6442                	ld	s0,16(sp)
    80003dd0:	6105                	addi	sp,sp,32
    80003dd2:	8082                	ret

0000000080003dd4 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003dd4:	1141                	addi	sp,sp,-16
    80003dd6:	e406                	sd	ra,8(sp)
    80003dd8:	e022                	sd	s0,0(sp)
    80003dda:	0800                	addi	s0,sp,16
    80003ddc:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003dde:	4585                	li	a1,1
    80003de0:	00000097          	auipc	ra,0x0
    80003de4:	dc4080e7          	jalr	-572(ra) # 80003ba4 <namex>
}
    80003de8:	60a2                	ld	ra,8(sp)
    80003dea:	6402                	ld	s0,0(sp)
    80003dec:	0141                	addi	sp,sp,16
    80003dee:	8082                	ret

0000000080003df0 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003df0:	1101                	addi	sp,sp,-32
    80003df2:	ec06                	sd	ra,24(sp)
    80003df4:	e822                	sd	s0,16(sp)
    80003df6:	e426                	sd	s1,8(sp)
    80003df8:	e04a                	sd	s2,0(sp)
    80003dfa:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003dfc:	0001d917          	auipc	s2,0x1d
    80003e00:	d2490913          	addi	s2,s2,-732 # 80020b20 <log>
    80003e04:	01892583          	lw	a1,24(s2)
    80003e08:	02892503          	lw	a0,40(s2)
    80003e0c:	fffff097          	auipc	ra,0xfffff
    80003e10:	ff4080e7          	jalr	-12(ra) # 80002e00 <bread>
    80003e14:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003e16:	02c92603          	lw	a2,44(s2)
    80003e1a:	cd30                	sw	a2,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003e1c:	00c05f63          	blez	a2,80003e3a <write_head+0x4a>
    80003e20:	0001d717          	auipc	a4,0x1d
    80003e24:	d3070713          	addi	a4,a4,-720 # 80020b50 <log+0x30>
    80003e28:	87aa                	mv	a5,a0
    80003e2a:	060a                	slli	a2,a2,0x2
    80003e2c:	962a                	add	a2,a2,a0
    hb->block[i] = log.lh.block[i];
    80003e2e:	4314                	lw	a3,0(a4)
    80003e30:	cff4                	sw	a3,92(a5)
  for (i = 0; i < log.lh.n; i++) {
    80003e32:	0711                	addi	a4,a4,4
    80003e34:	0791                	addi	a5,a5,4
    80003e36:	fec79ce3          	bne	a5,a2,80003e2e <write_head+0x3e>
  }
  bwrite(buf);
    80003e3a:	8526                	mv	a0,s1
    80003e3c:	fffff097          	auipc	ra,0xfffff
    80003e40:	0b6080e7          	jalr	182(ra) # 80002ef2 <bwrite>
  brelse(buf);
    80003e44:	8526                	mv	a0,s1
    80003e46:	fffff097          	auipc	ra,0xfffff
    80003e4a:	0ea080e7          	jalr	234(ra) # 80002f30 <brelse>
}
    80003e4e:	60e2                	ld	ra,24(sp)
    80003e50:	6442                	ld	s0,16(sp)
    80003e52:	64a2                	ld	s1,8(sp)
    80003e54:	6902                	ld	s2,0(sp)
    80003e56:	6105                	addi	sp,sp,32
    80003e58:	8082                	ret

0000000080003e5a <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003e5a:	0001d797          	auipc	a5,0x1d
    80003e5e:	cf27a783          	lw	a5,-782(a5) # 80020b4c <log+0x2c>
    80003e62:	0af05d63          	blez	a5,80003f1c <install_trans+0xc2>
{
    80003e66:	7139                	addi	sp,sp,-64
    80003e68:	fc06                	sd	ra,56(sp)
    80003e6a:	f822                	sd	s0,48(sp)
    80003e6c:	f426                	sd	s1,40(sp)
    80003e6e:	f04a                	sd	s2,32(sp)
    80003e70:	ec4e                	sd	s3,24(sp)
    80003e72:	e852                	sd	s4,16(sp)
    80003e74:	e456                	sd	s5,8(sp)
    80003e76:	e05a                	sd	s6,0(sp)
    80003e78:	0080                	addi	s0,sp,64
    80003e7a:	8b2a                	mv	s6,a0
    80003e7c:	0001da97          	auipc	s5,0x1d
    80003e80:	cd4a8a93          	addi	s5,s5,-812 # 80020b50 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003e84:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003e86:	0001d997          	auipc	s3,0x1d
    80003e8a:	c9a98993          	addi	s3,s3,-870 # 80020b20 <log>
    80003e8e:	a00d                	j	80003eb0 <install_trans+0x56>
    brelse(lbuf);
    80003e90:	854a                	mv	a0,s2
    80003e92:	fffff097          	auipc	ra,0xfffff
    80003e96:	09e080e7          	jalr	158(ra) # 80002f30 <brelse>
    brelse(dbuf);
    80003e9a:	8526                	mv	a0,s1
    80003e9c:	fffff097          	auipc	ra,0xfffff
    80003ea0:	094080e7          	jalr	148(ra) # 80002f30 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003ea4:	2a05                	addiw	s4,s4,1
    80003ea6:	0a91                	addi	s5,s5,4
    80003ea8:	02c9a783          	lw	a5,44(s3)
    80003eac:	04fa5e63          	bge	s4,a5,80003f08 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003eb0:	0189a583          	lw	a1,24(s3)
    80003eb4:	014585bb          	addw	a1,a1,s4
    80003eb8:	2585                	addiw	a1,a1,1
    80003eba:	0289a503          	lw	a0,40(s3)
    80003ebe:	fffff097          	auipc	ra,0xfffff
    80003ec2:	f42080e7          	jalr	-190(ra) # 80002e00 <bread>
    80003ec6:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80003ec8:	000aa583          	lw	a1,0(s5)
    80003ecc:	0289a503          	lw	a0,40(s3)
    80003ed0:	fffff097          	auipc	ra,0xfffff
    80003ed4:	f30080e7          	jalr	-208(ra) # 80002e00 <bread>
    80003ed8:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80003eda:	40000613          	li	a2,1024
    80003ede:	05890593          	addi	a1,s2,88
    80003ee2:	05850513          	addi	a0,a0,88
    80003ee6:	ffffd097          	auipc	ra,0xffffd
    80003eea:	e42080e7          	jalr	-446(ra) # 80000d28 <memmove>
    bwrite(dbuf);  // write dst to disk
    80003eee:	8526                	mv	a0,s1
    80003ef0:	fffff097          	auipc	ra,0xfffff
    80003ef4:	002080e7          	jalr	2(ra) # 80002ef2 <bwrite>
    if(recovering == 0)
    80003ef8:	f80b1ce3          	bnez	s6,80003e90 <install_trans+0x36>
      bunpin(dbuf);
    80003efc:	8526                	mv	a0,s1
    80003efe:	fffff097          	auipc	ra,0xfffff
    80003f02:	10a080e7          	jalr	266(ra) # 80003008 <bunpin>
    80003f06:	b769                	j	80003e90 <install_trans+0x36>
}
    80003f08:	70e2                	ld	ra,56(sp)
    80003f0a:	7442                	ld	s0,48(sp)
    80003f0c:	74a2                	ld	s1,40(sp)
    80003f0e:	7902                	ld	s2,32(sp)
    80003f10:	69e2                	ld	s3,24(sp)
    80003f12:	6a42                	ld	s4,16(sp)
    80003f14:	6aa2                	ld	s5,8(sp)
    80003f16:	6b02                	ld	s6,0(sp)
    80003f18:	6121                	addi	sp,sp,64
    80003f1a:	8082                	ret
    80003f1c:	8082                	ret

0000000080003f1e <initlog>:
{
    80003f1e:	7179                	addi	sp,sp,-48
    80003f20:	f406                	sd	ra,40(sp)
    80003f22:	f022                	sd	s0,32(sp)
    80003f24:	ec26                	sd	s1,24(sp)
    80003f26:	e84a                	sd	s2,16(sp)
    80003f28:	e44e                	sd	s3,8(sp)
    80003f2a:	1800                	addi	s0,sp,48
    80003f2c:	892a                	mv	s2,a0
    80003f2e:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80003f30:	0001d497          	auipc	s1,0x1d
    80003f34:	bf048493          	addi	s1,s1,-1040 # 80020b20 <log>
    80003f38:	00004597          	auipc	a1,0x4
    80003f3c:	71058593          	addi	a1,a1,1808 # 80008648 <syscalls+0x1d8>
    80003f40:	8526                	mv	a0,s1
    80003f42:	ffffd097          	auipc	ra,0xffffd
    80003f46:	bfe080e7          	jalr	-1026(ra) # 80000b40 <initlock>
  log.start = sb->logstart;
    80003f4a:	0149a583          	lw	a1,20(s3)
    80003f4e:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80003f50:	0109a783          	lw	a5,16(s3)
    80003f54:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80003f56:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80003f5a:	854a                	mv	a0,s2
    80003f5c:	fffff097          	auipc	ra,0xfffff
    80003f60:	ea4080e7          	jalr	-348(ra) # 80002e00 <bread>
  log.lh.n = lh->n;
    80003f64:	4d30                	lw	a2,88(a0)
    80003f66:	d4d0                	sw	a2,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80003f68:	00c05f63          	blez	a2,80003f86 <initlog+0x68>
    80003f6c:	87aa                	mv	a5,a0
    80003f6e:	0001d717          	auipc	a4,0x1d
    80003f72:	be270713          	addi	a4,a4,-1054 # 80020b50 <log+0x30>
    80003f76:	060a                	slli	a2,a2,0x2
    80003f78:	962a                	add	a2,a2,a0
    log.lh.block[i] = lh->block[i];
    80003f7a:	4ff4                	lw	a3,92(a5)
    80003f7c:	c314                	sw	a3,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003f7e:	0791                	addi	a5,a5,4
    80003f80:	0711                	addi	a4,a4,4
    80003f82:	fec79ce3          	bne	a5,a2,80003f7a <initlog+0x5c>
  brelse(buf);
    80003f86:	fffff097          	auipc	ra,0xfffff
    80003f8a:	faa080e7          	jalr	-86(ra) # 80002f30 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80003f8e:	4505                	li	a0,1
    80003f90:	00000097          	auipc	ra,0x0
    80003f94:	eca080e7          	jalr	-310(ra) # 80003e5a <install_trans>
  log.lh.n = 0;
    80003f98:	0001d797          	auipc	a5,0x1d
    80003f9c:	ba07aa23          	sw	zero,-1100(a5) # 80020b4c <log+0x2c>
  write_head(); // clear the log
    80003fa0:	00000097          	auipc	ra,0x0
    80003fa4:	e50080e7          	jalr	-432(ra) # 80003df0 <write_head>
}
    80003fa8:	70a2                	ld	ra,40(sp)
    80003faa:	7402                	ld	s0,32(sp)
    80003fac:	64e2                	ld	s1,24(sp)
    80003fae:	6942                	ld	s2,16(sp)
    80003fb0:	69a2                	ld	s3,8(sp)
    80003fb2:	6145                	addi	sp,sp,48
    80003fb4:	8082                	ret

0000000080003fb6 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80003fb6:	1101                	addi	sp,sp,-32
    80003fb8:	ec06                	sd	ra,24(sp)
    80003fba:	e822                	sd	s0,16(sp)
    80003fbc:	e426                	sd	s1,8(sp)
    80003fbe:	e04a                	sd	s2,0(sp)
    80003fc0:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80003fc2:	0001d517          	auipc	a0,0x1d
    80003fc6:	b5e50513          	addi	a0,a0,-1186 # 80020b20 <log>
    80003fca:	ffffd097          	auipc	ra,0xffffd
    80003fce:	c06080e7          	jalr	-1018(ra) # 80000bd0 <acquire>
  while(1){
    if(log.committing){
    80003fd2:	0001d497          	auipc	s1,0x1d
    80003fd6:	b4e48493          	addi	s1,s1,-1202 # 80020b20 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80003fda:	4979                	li	s2,30
    80003fdc:	a039                	j	80003fea <begin_op+0x34>
      sleep(&log, &log.lock);
    80003fde:	85a6                	mv	a1,s1
    80003fe0:	8526                	mv	a0,s1
    80003fe2:	ffffe097          	auipc	ra,0xffffe
    80003fe6:	05a080e7          	jalr	90(ra) # 8000203c <sleep>
    if(log.committing){
    80003fea:	50dc                	lw	a5,36(s1)
    80003fec:	fbed                	bnez	a5,80003fde <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80003fee:	5098                	lw	a4,32(s1)
    80003ff0:	2705                	addiw	a4,a4,1
    80003ff2:	0027179b          	slliw	a5,a4,0x2
    80003ff6:	9fb9                	addw	a5,a5,a4
    80003ff8:	0017979b          	slliw	a5,a5,0x1
    80003ffc:	54d4                	lw	a3,44(s1)
    80003ffe:	9fb5                	addw	a5,a5,a3
    80004000:	00f95963          	bge	s2,a5,80004012 <begin_op+0x5c>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004004:	85a6                	mv	a1,s1
    80004006:	8526                	mv	a0,s1
    80004008:	ffffe097          	auipc	ra,0xffffe
    8000400c:	034080e7          	jalr	52(ra) # 8000203c <sleep>
    80004010:	bfe9                	j	80003fea <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004012:	0001d517          	auipc	a0,0x1d
    80004016:	b0e50513          	addi	a0,a0,-1266 # 80020b20 <log>
    8000401a:	d118                	sw	a4,32(a0)
      release(&log.lock);
    8000401c:	ffffd097          	auipc	ra,0xffffd
    80004020:	c68080e7          	jalr	-920(ra) # 80000c84 <release>
      break;
    }
  }
}
    80004024:	60e2                	ld	ra,24(sp)
    80004026:	6442                	ld	s0,16(sp)
    80004028:	64a2                	ld	s1,8(sp)
    8000402a:	6902                	ld	s2,0(sp)
    8000402c:	6105                	addi	sp,sp,32
    8000402e:	8082                	ret

0000000080004030 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004030:	7139                	addi	sp,sp,-64
    80004032:	fc06                	sd	ra,56(sp)
    80004034:	f822                	sd	s0,48(sp)
    80004036:	f426                	sd	s1,40(sp)
    80004038:	f04a                	sd	s2,32(sp)
    8000403a:	ec4e                	sd	s3,24(sp)
    8000403c:	e852                	sd	s4,16(sp)
    8000403e:	e456                	sd	s5,8(sp)
    80004040:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004042:	0001d497          	auipc	s1,0x1d
    80004046:	ade48493          	addi	s1,s1,-1314 # 80020b20 <log>
    8000404a:	8526                	mv	a0,s1
    8000404c:	ffffd097          	auipc	ra,0xffffd
    80004050:	b84080e7          	jalr	-1148(ra) # 80000bd0 <acquire>
  log.outstanding -= 1;
    80004054:	509c                	lw	a5,32(s1)
    80004056:	37fd                	addiw	a5,a5,-1
    80004058:	0007891b          	sext.w	s2,a5
    8000405c:	d09c                	sw	a5,32(s1)
  if(log.committing)
    8000405e:	50dc                	lw	a5,36(s1)
    80004060:	e7b9                	bnez	a5,800040ae <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004062:	04091e63          	bnez	s2,800040be <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004066:	0001d497          	auipc	s1,0x1d
    8000406a:	aba48493          	addi	s1,s1,-1350 # 80020b20 <log>
    8000406e:	4785                	li	a5,1
    80004070:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004072:	8526                	mv	a0,s1
    80004074:	ffffd097          	auipc	ra,0xffffd
    80004078:	c10080e7          	jalr	-1008(ra) # 80000c84 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000407c:	54dc                	lw	a5,44(s1)
    8000407e:	06f04763          	bgtz	a5,800040ec <end_op+0xbc>
    acquire(&log.lock);
    80004082:	0001d497          	auipc	s1,0x1d
    80004086:	a9e48493          	addi	s1,s1,-1378 # 80020b20 <log>
    8000408a:	8526                	mv	a0,s1
    8000408c:	ffffd097          	auipc	ra,0xffffd
    80004090:	b44080e7          	jalr	-1212(ra) # 80000bd0 <acquire>
    log.committing = 0;
    80004094:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004098:	8526                	mv	a0,s1
    8000409a:	ffffe097          	auipc	ra,0xffffe
    8000409e:	006080e7          	jalr	6(ra) # 800020a0 <wakeup>
    release(&log.lock);
    800040a2:	8526                	mv	a0,s1
    800040a4:	ffffd097          	auipc	ra,0xffffd
    800040a8:	be0080e7          	jalr	-1056(ra) # 80000c84 <release>
}
    800040ac:	a03d                	j	800040da <end_op+0xaa>
    panic("log.committing");
    800040ae:	00004517          	auipc	a0,0x4
    800040b2:	5a250513          	addi	a0,a0,1442 # 80008650 <syscalls+0x1e0>
    800040b6:	ffffc097          	auipc	ra,0xffffc
    800040ba:	484080e7          	jalr	1156(ra) # 8000053a <panic>
    wakeup(&log);
    800040be:	0001d497          	auipc	s1,0x1d
    800040c2:	a6248493          	addi	s1,s1,-1438 # 80020b20 <log>
    800040c6:	8526                	mv	a0,s1
    800040c8:	ffffe097          	auipc	ra,0xffffe
    800040cc:	fd8080e7          	jalr	-40(ra) # 800020a0 <wakeup>
  release(&log.lock);
    800040d0:	8526                	mv	a0,s1
    800040d2:	ffffd097          	auipc	ra,0xffffd
    800040d6:	bb2080e7          	jalr	-1102(ra) # 80000c84 <release>
}
    800040da:	70e2                	ld	ra,56(sp)
    800040dc:	7442                	ld	s0,48(sp)
    800040de:	74a2                	ld	s1,40(sp)
    800040e0:	7902                	ld	s2,32(sp)
    800040e2:	69e2                	ld	s3,24(sp)
    800040e4:	6a42                	ld	s4,16(sp)
    800040e6:	6aa2                	ld	s5,8(sp)
    800040e8:	6121                	addi	sp,sp,64
    800040ea:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    800040ec:	0001da97          	auipc	s5,0x1d
    800040f0:	a64a8a93          	addi	s5,s5,-1436 # 80020b50 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800040f4:	0001da17          	auipc	s4,0x1d
    800040f8:	a2ca0a13          	addi	s4,s4,-1492 # 80020b20 <log>
    800040fc:	018a2583          	lw	a1,24(s4)
    80004100:	012585bb          	addw	a1,a1,s2
    80004104:	2585                	addiw	a1,a1,1
    80004106:	028a2503          	lw	a0,40(s4)
    8000410a:	fffff097          	auipc	ra,0xfffff
    8000410e:	cf6080e7          	jalr	-778(ra) # 80002e00 <bread>
    80004112:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004114:	000aa583          	lw	a1,0(s5)
    80004118:	028a2503          	lw	a0,40(s4)
    8000411c:	fffff097          	auipc	ra,0xfffff
    80004120:	ce4080e7          	jalr	-796(ra) # 80002e00 <bread>
    80004124:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004126:	40000613          	li	a2,1024
    8000412a:	05850593          	addi	a1,a0,88
    8000412e:	05848513          	addi	a0,s1,88
    80004132:	ffffd097          	auipc	ra,0xffffd
    80004136:	bf6080e7          	jalr	-1034(ra) # 80000d28 <memmove>
    bwrite(to);  // write the log
    8000413a:	8526                	mv	a0,s1
    8000413c:	fffff097          	auipc	ra,0xfffff
    80004140:	db6080e7          	jalr	-586(ra) # 80002ef2 <bwrite>
    brelse(from);
    80004144:	854e                	mv	a0,s3
    80004146:	fffff097          	auipc	ra,0xfffff
    8000414a:	dea080e7          	jalr	-534(ra) # 80002f30 <brelse>
    brelse(to);
    8000414e:	8526                	mv	a0,s1
    80004150:	fffff097          	auipc	ra,0xfffff
    80004154:	de0080e7          	jalr	-544(ra) # 80002f30 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004158:	2905                	addiw	s2,s2,1
    8000415a:	0a91                	addi	s5,s5,4
    8000415c:	02ca2783          	lw	a5,44(s4)
    80004160:	f8f94ee3          	blt	s2,a5,800040fc <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004164:	00000097          	auipc	ra,0x0
    80004168:	c8c080e7          	jalr	-884(ra) # 80003df0 <write_head>
    install_trans(0); // Now install writes to home locations
    8000416c:	4501                	li	a0,0
    8000416e:	00000097          	auipc	ra,0x0
    80004172:	cec080e7          	jalr	-788(ra) # 80003e5a <install_trans>
    log.lh.n = 0;
    80004176:	0001d797          	auipc	a5,0x1d
    8000417a:	9c07ab23          	sw	zero,-1578(a5) # 80020b4c <log+0x2c>
    write_head();    // Erase the transaction from the log
    8000417e:	00000097          	auipc	ra,0x0
    80004182:	c72080e7          	jalr	-910(ra) # 80003df0 <write_head>
    80004186:	bdf5                	j	80004082 <end_op+0x52>

0000000080004188 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004188:	1101                	addi	sp,sp,-32
    8000418a:	ec06                	sd	ra,24(sp)
    8000418c:	e822                	sd	s0,16(sp)
    8000418e:	e426                	sd	s1,8(sp)
    80004190:	e04a                	sd	s2,0(sp)
    80004192:	1000                	addi	s0,sp,32
    80004194:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004196:	0001d917          	auipc	s2,0x1d
    8000419a:	98a90913          	addi	s2,s2,-1654 # 80020b20 <log>
    8000419e:	854a                	mv	a0,s2
    800041a0:	ffffd097          	auipc	ra,0xffffd
    800041a4:	a30080e7          	jalr	-1488(ra) # 80000bd0 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800041a8:	02c92603          	lw	a2,44(s2)
    800041ac:	47f5                	li	a5,29
    800041ae:	06c7c563          	blt	a5,a2,80004218 <log_write+0x90>
    800041b2:	0001d797          	auipc	a5,0x1d
    800041b6:	98a7a783          	lw	a5,-1654(a5) # 80020b3c <log+0x1c>
    800041ba:	37fd                	addiw	a5,a5,-1
    800041bc:	04f65e63          	bge	a2,a5,80004218 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800041c0:	0001d797          	auipc	a5,0x1d
    800041c4:	9807a783          	lw	a5,-1664(a5) # 80020b40 <log+0x20>
    800041c8:	06f05063          	blez	a5,80004228 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800041cc:	4781                	li	a5,0
    800041ce:	06c05563          	blez	a2,80004238 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800041d2:	44cc                	lw	a1,12(s1)
    800041d4:	0001d717          	auipc	a4,0x1d
    800041d8:	97c70713          	addi	a4,a4,-1668 # 80020b50 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800041dc:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800041de:	4314                	lw	a3,0(a4)
    800041e0:	04b68c63          	beq	a3,a1,80004238 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800041e4:	2785                	addiw	a5,a5,1
    800041e6:	0711                	addi	a4,a4,4
    800041e8:	fef61be3          	bne	a2,a5,800041de <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800041ec:	0621                	addi	a2,a2,8
    800041ee:	060a                	slli	a2,a2,0x2
    800041f0:	0001d797          	auipc	a5,0x1d
    800041f4:	93078793          	addi	a5,a5,-1744 # 80020b20 <log>
    800041f8:	97b2                	add	a5,a5,a2
    800041fa:	44d8                	lw	a4,12(s1)
    800041fc:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800041fe:	8526                	mv	a0,s1
    80004200:	fffff097          	auipc	ra,0xfffff
    80004204:	dcc080e7          	jalr	-564(ra) # 80002fcc <bpin>
    log.lh.n++;
    80004208:	0001d717          	auipc	a4,0x1d
    8000420c:	91870713          	addi	a4,a4,-1768 # 80020b20 <log>
    80004210:	575c                	lw	a5,44(a4)
    80004212:	2785                	addiw	a5,a5,1
    80004214:	d75c                	sw	a5,44(a4)
    80004216:	a82d                	j	80004250 <log_write+0xc8>
    panic("too big a transaction");
    80004218:	00004517          	auipc	a0,0x4
    8000421c:	44850513          	addi	a0,a0,1096 # 80008660 <syscalls+0x1f0>
    80004220:	ffffc097          	auipc	ra,0xffffc
    80004224:	31a080e7          	jalr	794(ra) # 8000053a <panic>
    panic("log_write outside of trans");
    80004228:	00004517          	auipc	a0,0x4
    8000422c:	45050513          	addi	a0,a0,1104 # 80008678 <syscalls+0x208>
    80004230:	ffffc097          	auipc	ra,0xffffc
    80004234:	30a080e7          	jalr	778(ra) # 8000053a <panic>
  log.lh.block[i] = b->blockno;
    80004238:	00878693          	addi	a3,a5,8
    8000423c:	068a                	slli	a3,a3,0x2
    8000423e:	0001d717          	auipc	a4,0x1d
    80004242:	8e270713          	addi	a4,a4,-1822 # 80020b20 <log>
    80004246:	9736                	add	a4,a4,a3
    80004248:	44d4                	lw	a3,12(s1)
    8000424a:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000424c:	faf609e3          	beq	a2,a5,800041fe <log_write+0x76>
  }
  release(&log.lock);
    80004250:	0001d517          	auipc	a0,0x1d
    80004254:	8d050513          	addi	a0,a0,-1840 # 80020b20 <log>
    80004258:	ffffd097          	auipc	ra,0xffffd
    8000425c:	a2c080e7          	jalr	-1492(ra) # 80000c84 <release>
}
    80004260:	60e2                	ld	ra,24(sp)
    80004262:	6442                	ld	s0,16(sp)
    80004264:	64a2                	ld	s1,8(sp)
    80004266:	6902                	ld	s2,0(sp)
    80004268:	6105                	addi	sp,sp,32
    8000426a:	8082                	ret

000000008000426c <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000426c:	1101                	addi	sp,sp,-32
    8000426e:	ec06                	sd	ra,24(sp)
    80004270:	e822                	sd	s0,16(sp)
    80004272:	e426                	sd	s1,8(sp)
    80004274:	e04a                	sd	s2,0(sp)
    80004276:	1000                	addi	s0,sp,32
    80004278:	84aa                	mv	s1,a0
    8000427a:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    8000427c:	00004597          	auipc	a1,0x4
    80004280:	41c58593          	addi	a1,a1,1052 # 80008698 <syscalls+0x228>
    80004284:	0521                	addi	a0,a0,8
    80004286:	ffffd097          	auipc	ra,0xffffd
    8000428a:	8ba080e7          	jalr	-1862(ra) # 80000b40 <initlock>
  lk->name = name;
    8000428e:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004292:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004296:	0204a423          	sw	zero,40(s1)
}
    8000429a:	60e2                	ld	ra,24(sp)
    8000429c:	6442                	ld	s0,16(sp)
    8000429e:	64a2                	ld	s1,8(sp)
    800042a0:	6902                	ld	s2,0(sp)
    800042a2:	6105                	addi	sp,sp,32
    800042a4:	8082                	ret

00000000800042a6 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800042a6:	1101                	addi	sp,sp,-32
    800042a8:	ec06                	sd	ra,24(sp)
    800042aa:	e822                	sd	s0,16(sp)
    800042ac:	e426                	sd	s1,8(sp)
    800042ae:	e04a                	sd	s2,0(sp)
    800042b0:	1000                	addi	s0,sp,32
    800042b2:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800042b4:	00850913          	addi	s2,a0,8
    800042b8:	854a                	mv	a0,s2
    800042ba:	ffffd097          	auipc	ra,0xffffd
    800042be:	916080e7          	jalr	-1770(ra) # 80000bd0 <acquire>
  while (lk->locked) {
    800042c2:	409c                	lw	a5,0(s1)
    800042c4:	cb89                	beqz	a5,800042d6 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800042c6:	85ca                	mv	a1,s2
    800042c8:	8526                	mv	a0,s1
    800042ca:	ffffe097          	auipc	ra,0xffffe
    800042ce:	d72080e7          	jalr	-654(ra) # 8000203c <sleep>
  while (lk->locked) {
    800042d2:	409c                	lw	a5,0(s1)
    800042d4:	fbed                	bnez	a5,800042c6 <acquiresleep+0x20>
  }
  lk->locked = 1;
    800042d6:	4785                	li	a5,1
    800042d8:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800042da:	ffffd097          	auipc	ra,0xffffd
    800042de:	6ba080e7          	jalr	1722(ra) # 80001994 <myproc>
    800042e2:	591c                	lw	a5,48(a0)
    800042e4:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800042e6:	854a                	mv	a0,s2
    800042e8:	ffffd097          	auipc	ra,0xffffd
    800042ec:	99c080e7          	jalr	-1636(ra) # 80000c84 <release>
}
    800042f0:	60e2                	ld	ra,24(sp)
    800042f2:	6442                	ld	s0,16(sp)
    800042f4:	64a2                	ld	s1,8(sp)
    800042f6:	6902                	ld	s2,0(sp)
    800042f8:	6105                	addi	sp,sp,32
    800042fa:	8082                	ret

00000000800042fc <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800042fc:	1101                	addi	sp,sp,-32
    800042fe:	ec06                	sd	ra,24(sp)
    80004300:	e822                	sd	s0,16(sp)
    80004302:	e426                	sd	s1,8(sp)
    80004304:	e04a                	sd	s2,0(sp)
    80004306:	1000                	addi	s0,sp,32
    80004308:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000430a:	00850913          	addi	s2,a0,8
    8000430e:	854a                	mv	a0,s2
    80004310:	ffffd097          	auipc	ra,0xffffd
    80004314:	8c0080e7          	jalr	-1856(ra) # 80000bd0 <acquire>
  lk->locked = 0;
    80004318:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000431c:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004320:	8526                	mv	a0,s1
    80004322:	ffffe097          	auipc	ra,0xffffe
    80004326:	d7e080e7          	jalr	-642(ra) # 800020a0 <wakeup>
  release(&lk->lk);
    8000432a:	854a                	mv	a0,s2
    8000432c:	ffffd097          	auipc	ra,0xffffd
    80004330:	958080e7          	jalr	-1704(ra) # 80000c84 <release>
}
    80004334:	60e2                	ld	ra,24(sp)
    80004336:	6442                	ld	s0,16(sp)
    80004338:	64a2                	ld	s1,8(sp)
    8000433a:	6902                	ld	s2,0(sp)
    8000433c:	6105                	addi	sp,sp,32
    8000433e:	8082                	ret

0000000080004340 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004340:	7179                	addi	sp,sp,-48
    80004342:	f406                	sd	ra,40(sp)
    80004344:	f022                	sd	s0,32(sp)
    80004346:	ec26                	sd	s1,24(sp)
    80004348:	e84a                	sd	s2,16(sp)
    8000434a:	e44e                	sd	s3,8(sp)
    8000434c:	1800                	addi	s0,sp,48
    8000434e:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004350:	00850913          	addi	s2,a0,8
    80004354:	854a                	mv	a0,s2
    80004356:	ffffd097          	auipc	ra,0xffffd
    8000435a:	87a080e7          	jalr	-1926(ra) # 80000bd0 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    8000435e:	409c                	lw	a5,0(s1)
    80004360:	ef99                	bnez	a5,8000437e <holdingsleep+0x3e>
    80004362:	4481                	li	s1,0
  release(&lk->lk);
    80004364:	854a                	mv	a0,s2
    80004366:	ffffd097          	auipc	ra,0xffffd
    8000436a:	91e080e7          	jalr	-1762(ra) # 80000c84 <release>
  return r;
}
    8000436e:	8526                	mv	a0,s1
    80004370:	70a2                	ld	ra,40(sp)
    80004372:	7402                	ld	s0,32(sp)
    80004374:	64e2                	ld	s1,24(sp)
    80004376:	6942                	ld	s2,16(sp)
    80004378:	69a2                	ld	s3,8(sp)
    8000437a:	6145                	addi	sp,sp,48
    8000437c:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    8000437e:	0284a983          	lw	s3,40(s1)
    80004382:	ffffd097          	auipc	ra,0xffffd
    80004386:	612080e7          	jalr	1554(ra) # 80001994 <myproc>
    8000438a:	5904                	lw	s1,48(a0)
    8000438c:	413484b3          	sub	s1,s1,s3
    80004390:	0014b493          	seqz	s1,s1
    80004394:	bfc1                	j	80004364 <holdingsleep+0x24>

0000000080004396 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004396:	1141                	addi	sp,sp,-16
    80004398:	e406                	sd	ra,8(sp)
    8000439a:	e022                	sd	s0,0(sp)
    8000439c:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    8000439e:	00004597          	auipc	a1,0x4
    800043a2:	30a58593          	addi	a1,a1,778 # 800086a8 <syscalls+0x238>
    800043a6:	0001d517          	auipc	a0,0x1d
    800043aa:	8c250513          	addi	a0,a0,-1854 # 80020c68 <ftable>
    800043ae:	ffffc097          	auipc	ra,0xffffc
    800043b2:	792080e7          	jalr	1938(ra) # 80000b40 <initlock>
}
    800043b6:	60a2                	ld	ra,8(sp)
    800043b8:	6402                	ld	s0,0(sp)
    800043ba:	0141                	addi	sp,sp,16
    800043bc:	8082                	ret

00000000800043be <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800043be:	1101                	addi	sp,sp,-32
    800043c0:	ec06                	sd	ra,24(sp)
    800043c2:	e822                	sd	s0,16(sp)
    800043c4:	e426                	sd	s1,8(sp)
    800043c6:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800043c8:	0001d517          	auipc	a0,0x1d
    800043cc:	8a050513          	addi	a0,a0,-1888 # 80020c68 <ftable>
    800043d0:	ffffd097          	auipc	ra,0xffffd
    800043d4:	800080e7          	jalr	-2048(ra) # 80000bd0 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800043d8:	0001d497          	auipc	s1,0x1d
    800043dc:	8a848493          	addi	s1,s1,-1880 # 80020c80 <ftable+0x18>
    800043e0:	0001e717          	auipc	a4,0x1e
    800043e4:	84070713          	addi	a4,a4,-1984 # 80021c20 <disk>
    if(f->ref == 0){
    800043e8:	40dc                	lw	a5,4(s1)
    800043ea:	cf99                	beqz	a5,80004408 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800043ec:	02848493          	addi	s1,s1,40
    800043f0:	fee49ce3          	bne	s1,a4,800043e8 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800043f4:	0001d517          	auipc	a0,0x1d
    800043f8:	87450513          	addi	a0,a0,-1932 # 80020c68 <ftable>
    800043fc:	ffffd097          	auipc	ra,0xffffd
    80004400:	888080e7          	jalr	-1912(ra) # 80000c84 <release>
  return 0;
    80004404:	4481                	li	s1,0
    80004406:	a819                	j	8000441c <filealloc+0x5e>
      f->ref = 1;
    80004408:	4785                	li	a5,1
    8000440a:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    8000440c:	0001d517          	auipc	a0,0x1d
    80004410:	85c50513          	addi	a0,a0,-1956 # 80020c68 <ftable>
    80004414:	ffffd097          	auipc	ra,0xffffd
    80004418:	870080e7          	jalr	-1936(ra) # 80000c84 <release>
}
    8000441c:	8526                	mv	a0,s1
    8000441e:	60e2                	ld	ra,24(sp)
    80004420:	6442                	ld	s0,16(sp)
    80004422:	64a2                	ld	s1,8(sp)
    80004424:	6105                	addi	sp,sp,32
    80004426:	8082                	ret

0000000080004428 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004428:	1101                	addi	sp,sp,-32
    8000442a:	ec06                	sd	ra,24(sp)
    8000442c:	e822                	sd	s0,16(sp)
    8000442e:	e426                	sd	s1,8(sp)
    80004430:	1000                	addi	s0,sp,32
    80004432:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004434:	0001d517          	auipc	a0,0x1d
    80004438:	83450513          	addi	a0,a0,-1996 # 80020c68 <ftable>
    8000443c:	ffffc097          	auipc	ra,0xffffc
    80004440:	794080e7          	jalr	1940(ra) # 80000bd0 <acquire>
  if(f->ref < 1)
    80004444:	40dc                	lw	a5,4(s1)
    80004446:	02f05263          	blez	a5,8000446a <filedup+0x42>
    panic("filedup");
  f->ref++;
    8000444a:	2785                	addiw	a5,a5,1
    8000444c:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    8000444e:	0001d517          	auipc	a0,0x1d
    80004452:	81a50513          	addi	a0,a0,-2022 # 80020c68 <ftable>
    80004456:	ffffd097          	auipc	ra,0xffffd
    8000445a:	82e080e7          	jalr	-2002(ra) # 80000c84 <release>
  return f;
}
    8000445e:	8526                	mv	a0,s1
    80004460:	60e2                	ld	ra,24(sp)
    80004462:	6442                	ld	s0,16(sp)
    80004464:	64a2                	ld	s1,8(sp)
    80004466:	6105                	addi	sp,sp,32
    80004468:	8082                	ret
    panic("filedup");
    8000446a:	00004517          	auipc	a0,0x4
    8000446e:	24650513          	addi	a0,a0,582 # 800086b0 <syscalls+0x240>
    80004472:	ffffc097          	auipc	ra,0xffffc
    80004476:	0c8080e7          	jalr	200(ra) # 8000053a <panic>

000000008000447a <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    8000447a:	7139                	addi	sp,sp,-64
    8000447c:	fc06                	sd	ra,56(sp)
    8000447e:	f822                	sd	s0,48(sp)
    80004480:	f426                	sd	s1,40(sp)
    80004482:	f04a                	sd	s2,32(sp)
    80004484:	ec4e                	sd	s3,24(sp)
    80004486:	e852                	sd	s4,16(sp)
    80004488:	e456                	sd	s5,8(sp)
    8000448a:	0080                	addi	s0,sp,64
    8000448c:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    8000448e:	0001c517          	auipc	a0,0x1c
    80004492:	7da50513          	addi	a0,a0,2010 # 80020c68 <ftable>
    80004496:	ffffc097          	auipc	ra,0xffffc
    8000449a:	73a080e7          	jalr	1850(ra) # 80000bd0 <acquire>
  if(f->ref < 1)
    8000449e:	40dc                	lw	a5,4(s1)
    800044a0:	06f05163          	blez	a5,80004502 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800044a4:	37fd                	addiw	a5,a5,-1
    800044a6:	0007871b          	sext.w	a4,a5
    800044aa:	c0dc                	sw	a5,4(s1)
    800044ac:	06e04363          	bgtz	a4,80004512 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800044b0:	0004a903          	lw	s2,0(s1)
    800044b4:	0094ca83          	lbu	s5,9(s1)
    800044b8:	0104ba03          	ld	s4,16(s1)
    800044bc:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800044c0:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800044c4:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800044c8:	0001c517          	auipc	a0,0x1c
    800044cc:	7a050513          	addi	a0,a0,1952 # 80020c68 <ftable>
    800044d0:	ffffc097          	auipc	ra,0xffffc
    800044d4:	7b4080e7          	jalr	1972(ra) # 80000c84 <release>

  if(ff.type == FD_PIPE){
    800044d8:	4785                	li	a5,1
    800044da:	04f90d63          	beq	s2,a5,80004534 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800044de:	3979                	addiw	s2,s2,-2
    800044e0:	4785                	li	a5,1
    800044e2:	0527e063          	bltu	a5,s2,80004522 <fileclose+0xa8>
    begin_op();
    800044e6:	00000097          	auipc	ra,0x0
    800044ea:	ad0080e7          	jalr	-1328(ra) # 80003fb6 <begin_op>
    iput(ff.ip);
    800044ee:	854e                	mv	a0,s3
    800044f0:	fffff097          	auipc	ra,0xfffff
    800044f4:	2da080e7          	jalr	730(ra) # 800037ca <iput>
    end_op();
    800044f8:	00000097          	auipc	ra,0x0
    800044fc:	b38080e7          	jalr	-1224(ra) # 80004030 <end_op>
    80004500:	a00d                	j	80004522 <fileclose+0xa8>
    panic("fileclose");
    80004502:	00004517          	auipc	a0,0x4
    80004506:	1b650513          	addi	a0,a0,438 # 800086b8 <syscalls+0x248>
    8000450a:	ffffc097          	auipc	ra,0xffffc
    8000450e:	030080e7          	jalr	48(ra) # 8000053a <panic>
    release(&ftable.lock);
    80004512:	0001c517          	auipc	a0,0x1c
    80004516:	75650513          	addi	a0,a0,1878 # 80020c68 <ftable>
    8000451a:	ffffc097          	auipc	ra,0xffffc
    8000451e:	76a080e7          	jalr	1898(ra) # 80000c84 <release>
  }
}
    80004522:	70e2                	ld	ra,56(sp)
    80004524:	7442                	ld	s0,48(sp)
    80004526:	74a2                	ld	s1,40(sp)
    80004528:	7902                	ld	s2,32(sp)
    8000452a:	69e2                	ld	s3,24(sp)
    8000452c:	6a42                	ld	s4,16(sp)
    8000452e:	6aa2                	ld	s5,8(sp)
    80004530:	6121                	addi	sp,sp,64
    80004532:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004534:	85d6                	mv	a1,s5
    80004536:	8552                	mv	a0,s4
    80004538:	00000097          	auipc	ra,0x0
    8000453c:	348080e7          	jalr	840(ra) # 80004880 <pipeclose>
    80004540:	b7cd                	j	80004522 <fileclose+0xa8>

0000000080004542 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004542:	715d                	addi	sp,sp,-80
    80004544:	e486                	sd	ra,72(sp)
    80004546:	e0a2                	sd	s0,64(sp)
    80004548:	fc26                	sd	s1,56(sp)
    8000454a:	f84a                	sd	s2,48(sp)
    8000454c:	f44e                	sd	s3,40(sp)
    8000454e:	0880                	addi	s0,sp,80
    80004550:	84aa                	mv	s1,a0
    80004552:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004554:	ffffd097          	auipc	ra,0xffffd
    80004558:	440080e7          	jalr	1088(ra) # 80001994 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    8000455c:	409c                	lw	a5,0(s1)
    8000455e:	37f9                	addiw	a5,a5,-2
    80004560:	4705                	li	a4,1
    80004562:	04f76763          	bltu	a4,a5,800045b0 <filestat+0x6e>
    80004566:	892a                	mv	s2,a0
    ilock(f->ip);
    80004568:	6c88                	ld	a0,24(s1)
    8000456a:	fffff097          	auipc	ra,0xfffff
    8000456e:	0a6080e7          	jalr	166(ra) # 80003610 <ilock>
    stati(f->ip, &st);
    80004572:	fb840593          	addi	a1,s0,-72
    80004576:	6c88                	ld	a0,24(s1)
    80004578:	fffff097          	auipc	ra,0xfffff
    8000457c:	322080e7          	jalr	802(ra) # 8000389a <stati>
    iunlock(f->ip);
    80004580:	6c88                	ld	a0,24(s1)
    80004582:	fffff097          	auipc	ra,0xfffff
    80004586:	150080e7          	jalr	336(ra) # 800036d2 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    8000458a:	46e1                	li	a3,24
    8000458c:	fb840613          	addi	a2,s0,-72
    80004590:	85ce                	mv	a1,s3
    80004592:	05093503          	ld	a0,80(s2)
    80004596:	ffffd097          	auipc	ra,0xffffd
    8000459a:	0be080e7          	jalr	190(ra) # 80001654 <copyout>
    8000459e:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800045a2:	60a6                	ld	ra,72(sp)
    800045a4:	6406                	ld	s0,64(sp)
    800045a6:	74e2                	ld	s1,56(sp)
    800045a8:	7942                	ld	s2,48(sp)
    800045aa:	79a2                	ld	s3,40(sp)
    800045ac:	6161                	addi	sp,sp,80
    800045ae:	8082                	ret
  return -1;
    800045b0:	557d                	li	a0,-1
    800045b2:	bfc5                	j	800045a2 <filestat+0x60>

00000000800045b4 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800045b4:	7179                	addi	sp,sp,-48
    800045b6:	f406                	sd	ra,40(sp)
    800045b8:	f022                	sd	s0,32(sp)
    800045ba:	ec26                	sd	s1,24(sp)
    800045bc:	e84a                	sd	s2,16(sp)
    800045be:	e44e                	sd	s3,8(sp)
    800045c0:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800045c2:	00854783          	lbu	a5,8(a0)
    800045c6:	c3d5                	beqz	a5,8000466a <fileread+0xb6>
    800045c8:	84aa                	mv	s1,a0
    800045ca:	89ae                	mv	s3,a1
    800045cc:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800045ce:	411c                	lw	a5,0(a0)
    800045d0:	4705                	li	a4,1
    800045d2:	04e78963          	beq	a5,a4,80004624 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800045d6:	470d                	li	a4,3
    800045d8:	04e78d63          	beq	a5,a4,80004632 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800045dc:	4709                	li	a4,2
    800045de:	06e79e63          	bne	a5,a4,8000465a <fileread+0xa6>
    ilock(f->ip);
    800045e2:	6d08                	ld	a0,24(a0)
    800045e4:	fffff097          	auipc	ra,0xfffff
    800045e8:	02c080e7          	jalr	44(ra) # 80003610 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800045ec:	874a                	mv	a4,s2
    800045ee:	5094                	lw	a3,32(s1)
    800045f0:	864e                	mv	a2,s3
    800045f2:	4585                	li	a1,1
    800045f4:	6c88                	ld	a0,24(s1)
    800045f6:	fffff097          	auipc	ra,0xfffff
    800045fa:	2ce080e7          	jalr	718(ra) # 800038c4 <readi>
    800045fe:	892a                	mv	s2,a0
    80004600:	00a05563          	blez	a0,8000460a <fileread+0x56>
      f->off += r;
    80004604:	509c                	lw	a5,32(s1)
    80004606:	9fa9                	addw	a5,a5,a0
    80004608:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    8000460a:	6c88                	ld	a0,24(s1)
    8000460c:	fffff097          	auipc	ra,0xfffff
    80004610:	0c6080e7          	jalr	198(ra) # 800036d2 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004614:	854a                	mv	a0,s2
    80004616:	70a2                	ld	ra,40(sp)
    80004618:	7402                	ld	s0,32(sp)
    8000461a:	64e2                	ld	s1,24(sp)
    8000461c:	6942                	ld	s2,16(sp)
    8000461e:	69a2                	ld	s3,8(sp)
    80004620:	6145                	addi	sp,sp,48
    80004622:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004624:	6908                	ld	a0,16(a0)
    80004626:	00000097          	auipc	ra,0x0
    8000462a:	3c2080e7          	jalr	962(ra) # 800049e8 <piperead>
    8000462e:	892a                	mv	s2,a0
    80004630:	b7d5                	j	80004614 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004632:	02451783          	lh	a5,36(a0)
    80004636:	03079693          	slli	a3,a5,0x30
    8000463a:	92c1                	srli	a3,a3,0x30
    8000463c:	4725                	li	a4,9
    8000463e:	02d76863          	bltu	a4,a3,8000466e <fileread+0xba>
    80004642:	0792                	slli	a5,a5,0x4
    80004644:	0001c717          	auipc	a4,0x1c
    80004648:	58470713          	addi	a4,a4,1412 # 80020bc8 <devsw>
    8000464c:	97ba                	add	a5,a5,a4
    8000464e:	639c                	ld	a5,0(a5)
    80004650:	c38d                	beqz	a5,80004672 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004652:	4505                	li	a0,1
    80004654:	9782                	jalr	a5
    80004656:	892a                	mv	s2,a0
    80004658:	bf75                	j	80004614 <fileread+0x60>
    panic("fileread");
    8000465a:	00004517          	auipc	a0,0x4
    8000465e:	06e50513          	addi	a0,a0,110 # 800086c8 <syscalls+0x258>
    80004662:	ffffc097          	auipc	ra,0xffffc
    80004666:	ed8080e7          	jalr	-296(ra) # 8000053a <panic>
    return -1;
    8000466a:	597d                	li	s2,-1
    8000466c:	b765                	j	80004614 <fileread+0x60>
      return -1;
    8000466e:	597d                	li	s2,-1
    80004670:	b755                	j	80004614 <fileread+0x60>
    80004672:	597d                	li	s2,-1
    80004674:	b745                	j	80004614 <fileread+0x60>

0000000080004676 <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    80004676:	00954783          	lbu	a5,9(a0)
    8000467a:	10078e63          	beqz	a5,80004796 <filewrite+0x120>
{
    8000467e:	715d                	addi	sp,sp,-80
    80004680:	e486                	sd	ra,72(sp)
    80004682:	e0a2                	sd	s0,64(sp)
    80004684:	fc26                	sd	s1,56(sp)
    80004686:	f84a                	sd	s2,48(sp)
    80004688:	f44e                	sd	s3,40(sp)
    8000468a:	f052                	sd	s4,32(sp)
    8000468c:	ec56                	sd	s5,24(sp)
    8000468e:	e85a                	sd	s6,16(sp)
    80004690:	e45e                	sd	s7,8(sp)
    80004692:	e062                	sd	s8,0(sp)
    80004694:	0880                	addi	s0,sp,80
    80004696:	892a                	mv	s2,a0
    80004698:	8b2e                	mv	s6,a1
    8000469a:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    8000469c:	411c                	lw	a5,0(a0)
    8000469e:	4705                	li	a4,1
    800046a0:	02e78263          	beq	a5,a4,800046c4 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800046a4:	470d                	li	a4,3
    800046a6:	02e78563          	beq	a5,a4,800046d0 <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800046aa:	4709                	li	a4,2
    800046ac:	0ce79d63          	bne	a5,a4,80004786 <filewrite+0x110>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800046b0:	0ac05b63          	blez	a2,80004766 <filewrite+0xf0>
    int i = 0;
    800046b4:	4981                	li	s3,0
      int n1 = n - i;
      if(n1 > max)
    800046b6:	6b85                	lui	s7,0x1
    800046b8:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    800046bc:	6c05                	lui	s8,0x1
    800046be:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    800046c2:	a851                	j	80004756 <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    800046c4:	6908                	ld	a0,16(a0)
    800046c6:	00000097          	auipc	ra,0x0
    800046ca:	22a080e7          	jalr	554(ra) # 800048f0 <pipewrite>
    800046ce:	a045                	j	8000476e <filewrite+0xf8>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800046d0:	02451783          	lh	a5,36(a0)
    800046d4:	03079693          	slli	a3,a5,0x30
    800046d8:	92c1                	srli	a3,a3,0x30
    800046da:	4725                	li	a4,9
    800046dc:	0ad76f63          	bltu	a4,a3,8000479a <filewrite+0x124>
    800046e0:	0792                	slli	a5,a5,0x4
    800046e2:	0001c717          	auipc	a4,0x1c
    800046e6:	4e670713          	addi	a4,a4,1254 # 80020bc8 <devsw>
    800046ea:	97ba                	add	a5,a5,a4
    800046ec:	679c                	ld	a5,8(a5)
    800046ee:	cbc5                	beqz	a5,8000479e <filewrite+0x128>
    ret = devsw[f->major].write(1, addr, n);
    800046f0:	4505                	li	a0,1
    800046f2:	9782                	jalr	a5
    800046f4:	a8ad                	j	8000476e <filewrite+0xf8>
      if(n1 > max)
    800046f6:	00048a9b          	sext.w	s5,s1
        n1 = max;

      begin_op();
    800046fa:	00000097          	auipc	ra,0x0
    800046fe:	8bc080e7          	jalr	-1860(ra) # 80003fb6 <begin_op>
      ilock(f->ip);
    80004702:	01893503          	ld	a0,24(s2)
    80004706:	fffff097          	auipc	ra,0xfffff
    8000470a:	f0a080e7          	jalr	-246(ra) # 80003610 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    8000470e:	8756                	mv	a4,s5
    80004710:	02092683          	lw	a3,32(s2)
    80004714:	01698633          	add	a2,s3,s6
    80004718:	4585                	li	a1,1
    8000471a:	01893503          	ld	a0,24(s2)
    8000471e:	fffff097          	auipc	ra,0xfffff
    80004722:	29e080e7          	jalr	670(ra) # 800039bc <writei>
    80004726:	84aa                	mv	s1,a0
    80004728:	00a05763          	blez	a0,80004736 <filewrite+0xc0>
        f->off += r;
    8000472c:	02092783          	lw	a5,32(s2)
    80004730:	9fa9                	addw	a5,a5,a0
    80004732:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004736:	01893503          	ld	a0,24(s2)
    8000473a:	fffff097          	auipc	ra,0xfffff
    8000473e:	f98080e7          	jalr	-104(ra) # 800036d2 <iunlock>
      end_op();
    80004742:	00000097          	auipc	ra,0x0
    80004746:	8ee080e7          	jalr	-1810(ra) # 80004030 <end_op>

      if(r != n1){
    8000474a:	009a9f63          	bne	s5,s1,80004768 <filewrite+0xf2>
        // error from writei
        break;
      }
      i += r;
    8000474e:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004752:	0149db63          	bge	s3,s4,80004768 <filewrite+0xf2>
      int n1 = n - i;
    80004756:	413a04bb          	subw	s1,s4,s3
      if(n1 > max)
    8000475a:	0004879b          	sext.w	a5,s1
    8000475e:	f8fbdce3          	bge	s7,a5,800046f6 <filewrite+0x80>
    80004762:	84e2                	mv	s1,s8
    80004764:	bf49                	j	800046f6 <filewrite+0x80>
    int i = 0;
    80004766:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004768:	033a1d63          	bne	s4,s3,800047a2 <filewrite+0x12c>
    8000476c:	8552                	mv	a0,s4
  } else {
    panic("filewrite");
  }

  return ret;
}
    8000476e:	60a6                	ld	ra,72(sp)
    80004770:	6406                	ld	s0,64(sp)
    80004772:	74e2                	ld	s1,56(sp)
    80004774:	7942                	ld	s2,48(sp)
    80004776:	79a2                	ld	s3,40(sp)
    80004778:	7a02                	ld	s4,32(sp)
    8000477a:	6ae2                	ld	s5,24(sp)
    8000477c:	6b42                	ld	s6,16(sp)
    8000477e:	6ba2                	ld	s7,8(sp)
    80004780:	6c02                	ld	s8,0(sp)
    80004782:	6161                	addi	sp,sp,80
    80004784:	8082                	ret
    panic("filewrite");
    80004786:	00004517          	auipc	a0,0x4
    8000478a:	f5250513          	addi	a0,a0,-174 # 800086d8 <syscalls+0x268>
    8000478e:	ffffc097          	auipc	ra,0xffffc
    80004792:	dac080e7          	jalr	-596(ra) # 8000053a <panic>
    return -1;
    80004796:	557d                	li	a0,-1
}
    80004798:	8082                	ret
      return -1;
    8000479a:	557d                	li	a0,-1
    8000479c:	bfc9                	j	8000476e <filewrite+0xf8>
    8000479e:	557d                	li	a0,-1
    800047a0:	b7f9                	j	8000476e <filewrite+0xf8>
    ret = (i == n ? n : -1);
    800047a2:	557d                	li	a0,-1
    800047a4:	b7e9                	j	8000476e <filewrite+0xf8>

00000000800047a6 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    800047a6:	7179                	addi	sp,sp,-48
    800047a8:	f406                	sd	ra,40(sp)
    800047aa:	f022                	sd	s0,32(sp)
    800047ac:	ec26                	sd	s1,24(sp)
    800047ae:	e84a                	sd	s2,16(sp)
    800047b0:	e44e                	sd	s3,8(sp)
    800047b2:	e052                	sd	s4,0(sp)
    800047b4:	1800                	addi	s0,sp,48
    800047b6:	84aa                	mv	s1,a0
    800047b8:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800047ba:	0005b023          	sd	zero,0(a1)
    800047be:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800047c2:	00000097          	auipc	ra,0x0
    800047c6:	bfc080e7          	jalr	-1028(ra) # 800043be <filealloc>
    800047ca:	e088                	sd	a0,0(s1)
    800047cc:	c551                	beqz	a0,80004858 <pipealloc+0xb2>
    800047ce:	00000097          	auipc	ra,0x0
    800047d2:	bf0080e7          	jalr	-1040(ra) # 800043be <filealloc>
    800047d6:	00aa3023          	sd	a0,0(s4)
    800047da:	c92d                	beqz	a0,8000484c <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800047dc:	ffffc097          	auipc	ra,0xffffc
    800047e0:	304080e7          	jalr	772(ra) # 80000ae0 <kalloc>
    800047e4:	892a                	mv	s2,a0
    800047e6:	c125                	beqz	a0,80004846 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    800047e8:	4985                	li	s3,1
    800047ea:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800047ee:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800047f2:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800047f6:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800047fa:	00004597          	auipc	a1,0x4
    800047fe:	eee58593          	addi	a1,a1,-274 # 800086e8 <syscalls+0x278>
    80004802:	ffffc097          	auipc	ra,0xffffc
    80004806:	33e080e7          	jalr	830(ra) # 80000b40 <initlock>
  (*f0)->type = FD_PIPE;
    8000480a:	609c                	ld	a5,0(s1)
    8000480c:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004810:	609c                	ld	a5,0(s1)
    80004812:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004816:	609c                	ld	a5,0(s1)
    80004818:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    8000481c:	609c                	ld	a5,0(s1)
    8000481e:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004822:	000a3783          	ld	a5,0(s4)
    80004826:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    8000482a:	000a3783          	ld	a5,0(s4)
    8000482e:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004832:	000a3783          	ld	a5,0(s4)
    80004836:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    8000483a:	000a3783          	ld	a5,0(s4)
    8000483e:	0127b823          	sd	s2,16(a5)
  return 0;
    80004842:	4501                	li	a0,0
    80004844:	a025                	j	8000486c <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004846:	6088                	ld	a0,0(s1)
    80004848:	e501                	bnez	a0,80004850 <pipealloc+0xaa>
    8000484a:	a039                	j	80004858 <pipealloc+0xb2>
    8000484c:	6088                	ld	a0,0(s1)
    8000484e:	c51d                	beqz	a0,8000487c <pipealloc+0xd6>
    fileclose(*f0);
    80004850:	00000097          	auipc	ra,0x0
    80004854:	c2a080e7          	jalr	-982(ra) # 8000447a <fileclose>
  if(*f1)
    80004858:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    8000485c:	557d                	li	a0,-1
  if(*f1)
    8000485e:	c799                	beqz	a5,8000486c <pipealloc+0xc6>
    fileclose(*f1);
    80004860:	853e                	mv	a0,a5
    80004862:	00000097          	auipc	ra,0x0
    80004866:	c18080e7          	jalr	-1000(ra) # 8000447a <fileclose>
  return -1;
    8000486a:	557d                	li	a0,-1
}
    8000486c:	70a2                	ld	ra,40(sp)
    8000486e:	7402                	ld	s0,32(sp)
    80004870:	64e2                	ld	s1,24(sp)
    80004872:	6942                	ld	s2,16(sp)
    80004874:	69a2                	ld	s3,8(sp)
    80004876:	6a02                	ld	s4,0(sp)
    80004878:	6145                	addi	sp,sp,48
    8000487a:	8082                	ret
  return -1;
    8000487c:	557d                	li	a0,-1
    8000487e:	b7fd                	j	8000486c <pipealloc+0xc6>

0000000080004880 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004880:	1101                	addi	sp,sp,-32
    80004882:	ec06                	sd	ra,24(sp)
    80004884:	e822                	sd	s0,16(sp)
    80004886:	e426                	sd	s1,8(sp)
    80004888:	e04a                	sd	s2,0(sp)
    8000488a:	1000                	addi	s0,sp,32
    8000488c:	84aa                	mv	s1,a0
    8000488e:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004890:	ffffc097          	auipc	ra,0xffffc
    80004894:	340080e7          	jalr	832(ra) # 80000bd0 <acquire>
  if(writable){
    80004898:	02090d63          	beqz	s2,800048d2 <pipeclose+0x52>
    pi->writeopen = 0;
    8000489c:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    800048a0:	21848513          	addi	a0,s1,536
    800048a4:	ffffd097          	auipc	ra,0xffffd
    800048a8:	7fc080e7          	jalr	2044(ra) # 800020a0 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    800048ac:	2204b783          	ld	a5,544(s1)
    800048b0:	eb95                	bnez	a5,800048e4 <pipeclose+0x64>
    release(&pi->lock);
    800048b2:	8526                	mv	a0,s1
    800048b4:	ffffc097          	auipc	ra,0xffffc
    800048b8:	3d0080e7          	jalr	976(ra) # 80000c84 <release>
    kfree((char*)pi);
    800048bc:	8526                	mv	a0,s1
    800048be:	ffffc097          	auipc	ra,0xffffc
    800048c2:	124080e7          	jalr	292(ra) # 800009e2 <kfree>
  } else
    release(&pi->lock);
}
    800048c6:	60e2                	ld	ra,24(sp)
    800048c8:	6442                	ld	s0,16(sp)
    800048ca:	64a2                	ld	s1,8(sp)
    800048cc:	6902                	ld	s2,0(sp)
    800048ce:	6105                	addi	sp,sp,32
    800048d0:	8082                	ret
    pi->readopen = 0;
    800048d2:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    800048d6:	21c48513          	addi	a0,s1,540
    800048da:	ffffd097          	auipc	ra,0xffffd
    800048de:	7c6080e7          	jalr	1990(ra) # 800020a0 <wakeup>
    800048e2:	b7e9                	j	800048ac <pipeclose+0x2c>
    release(&pi->lock);
    800048e4:	8526                	mv	a0,s1
    800048e6:	ffffc097          	auipc	ra,0xffffc
    800048ea:	39e080e7          	jalr	926(ra) # 80000c84 <release>
}
    800048ee:	bfe1                	j	800048c6 <pipeclose+0x46>

00000000800048f0 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    800048f0:	711d                	addi	sp,sp,-96
    800048f2:	ec86                	sd	ra,88(sp)
    800048f4:	e8a2                	sd	s0,80(sp)
    800048f6:	e4a6                	sd	s1,72(sp)
    800048f8:	e0ca                	sd	s2,64(sp)
    800048fa:	fc4e                	sd	s3,56(sp)
    800048fc:	f852                	sd	s4,48(sp)
    800048fe:	f456                	sd	s5,40(sp)
    80004900:	f05a                	sd	s6,32(sp)
    80004902:	ec5e                	sd	s7,24(sp)
    80004904:	e862                	sd	s8,16(sp)
    80004906:	1080                	addi	s0,sp,96
    80004908:	84aa                	mv	s1,a0
    8000490a:	8aae                	mv	s5,a1
    8000490c:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    8000490e:	ffffd097          	auipc	ra,0xffffd
    80004912:	086080e7          	jalr	134(ra) # 80001994 <myproc>
    80004916:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004918:	8526                	mv	a0,s1
    8000491a:	ffffc097          	auipc	ra,0xffffc
    8000491e:	2b6080e7          	jalr	694(ra) # 80000bd0 <acquire>
  while(i < n){
    80004922:	0b405663          	blez	s4,800049ce <pipewrite+0xde>
  int i = 0;
    80004926:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004928:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    8000492a:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    8000492e:	21c48b93          	addi	s7,s1,540
    80004932:	a089                	j	80004974 <pipewrite+0x84>
      release(&pi->lock);
    80004934:	8526                	mv	a0,s1
    80004936:	ffffc097          	auipc	ra,0xffffc
    8000493a:	34e080e7          	jalr	846(ra) # 80000c84 <release>
      return -1;
    8000493e:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004940:	854a                	mv	a0,s2
    80004942:	60e6                	ld	ra,88(sp)
    80004944:	6446                	ld	s0,80(sp)
    80004946:	64a6                	ld	s1,72(sp)
    80004948:	6906                	ld	s2,64(sp)
    8000494a:	79e2                	ld	s3,56(sp)
    8000494c:	7a42                	ld	s4,48(sp)
    8000494e:	7aa2                	ld	s5,40(sp)
    80004950:	7b02                	ld	s6,32(sp)
    80004952:	6be2                	ld	s7,24(sp)
    80004954:	6c42                	ld	s8,16(sp)
    80004956:	6125                	addi	sp,sp,96
    80004958:	8082                	ret
      wakeup(&pi->nread);
    8000495a:	8562                	mv	a0,s8
    8000495c:	ffffd097          	auipc	ra,0xffffd
    80004960:	744080e7          	jalr	1860(ra) # 800020a0 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004964:	85a6                	mv	a1,s1
    80004966:	855e                	mv	a0,s7
    80004968:	ffffd097          	auipc	ra,0xffffd
    8000496c:	6d4080e7          	jalr	1748(ra) # 8000203c <sleep>
  while(i < n){
    80004970:	07495063          	bge	s2,s4,800049d0 <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80004974:	2204a783          	lw	a5,544(s1)
    80004978:	dfd5                	beqz	a5,80004934 <pipewrite+0x44>
    8000497a:	854e                	mv	a0,s3
    8000497c:	ffffe097          	auipc	ra,0xffffe
    80004980:	968080e7          	jalr	-1688(ra) # 800022e4 <killed>
    80004984:	f945                	bnez	a0,80004934 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004986:	2184a783          	lw	a5,536(s1)
    8000498a:	21c4a703          	lw	a4,540(s1)
    8000498e:	2007879b          	addiw	a5,a5,512
    80004992:	fcf704e3          	beq	a4,a5,8000495a <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004996:	4685                	li	a3,1
    80004998:	01590633          	add	a2,s2,s5
    8000499c:	faf40593          	addi	a1,s0,-81
    800049a0:	0509b503          	ld	a0,80(s3)
    800049a4:	ffffd097          	auipc	ra,0xffffd
    800049a8:	d3c080e7          	jalr	-708(ra) # 800016e0 <copyin>
    800049ac:	03650263          	beq	a0,s6,800049d0 <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    800049b0:	21c4a783          	lw	a5,540(s1)
    800049b4:	0017871b          	addiw	a4,a5,1
    800049b8:	20e4ae23          	sw	a4,540(s1)
    800049bc:	1ff7f793          	andi	a5,a5,511
    800049c0:	97a6                	add	a5,a5,s1
    800049c2:	faf44703          	lbu	a4,-81(s0)
    800049c6:	00e78c23          	sb	a4,24(a5)
      i++;
    800049ca:	2905                	addiw	s2,s2,1
    800049cc:	b755                	j	80004970 <pipewrite+0x80>
  int i = 0;
    800049ce:	4901                	li	s2,0
  wakeup(&pi->nread);
    800049d0:	21848513          	addi	a0,s1,536
    800049d4:	ffffd097          	auipc	ra,0xffffd
    800049d8:	6cc080e7          	jalr	1740(ra) # 800020a0 <wakeup>
  release(&pi->lock);
    800049dc:	8526                	mv	a0,s1
    800049de:	ffffc097          	auipc	ra,0xffffc
    800049e2:	2a6080e7          	jalr	678(ra) # 80000c84 <release>
  return i;
    800049e6:	bfa9                	j	80004940 <pipewrite+0x50>

00000000800049e8 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    800049e8:	715d                	addi	sp,sp,-80
    800049ea:	e486                	sd	ra,72(sp)
    800049ec:	e0a2                	sd	s0,64(sp)
    800049ee:	fc26                	sd	s1,56(sp)
    800049f0:	f84a                	sd	s2,48(sp)
    800049f2:	f44e                	sd	s3,40(sp)
    800049f4:	f052                	sd	s4,32(sp)
    800049f6:	ec56                	sd	s5,24(sp)
    800049f8:	e85a                	sd	s6,16(sp)
    800049fa:	0880                	addi	s0,sp,80
    800049fc:	84aa                	mv	s1,a0
    800049fe:	892e                	mv	s2,a1
    80004a00:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004a02:	ffffd097          	auipc	ra,0xffffd
    80004a06:	f92080e7          	jalr	-110(ra) # 80001994 <myproc>
    80004a0a:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004a0c:	8526                	mv	a0,s1
    80004a0e:	ffffc097          	auipc	ra,0xffffc
    80004a12:	1c2080e7          	jalr	450(ra) # 80000bd0 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004a16:	2184a703          	lw	a4,536(s1)
    80004a1a:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004a1e:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004a22:	02f71763          	bne	a4,a5,80004a50 <piperead+0x68>
    80004a26:	2244a783          	lw	a5,548(s1)
    80004a2a:	c39d                	beqz	a5,80004a50 <piperead+0x68>
    if(killed(pr)){
    80004a2c:	8552                	mv	a0,s4
    80004a2e:	ffffe097          	auipc	ra,0xffffe
    80004a32:	8b6080e7          	jalr	-1866(ra) # 800022e4 <killed>
    80004a36:	e949                	bnez	a0,80004ac8 <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004a38:	85a6                	mv	a1,s1
    80004a3a:	854e                	mv	a0,s3
    80004a3c:	ffffd097          	auipc	ra,0xffffd
    80004a40:	600080e7          	jalr	1536(ra) # 8000203c <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004a44:	2184a703          	lw	a4,536(s1)
    80004a48:	21c4a783          	lw	a5,540(s1)
    80004a4c:	fcf70de3          	beq	a4,a5,80004a26 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004a50:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004a52:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004a54:	05505463          	blez	s5,80004a9c <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    80004a58:	2184a783          	lw	a5,536(s1)
    80004a5c:	21c4a703          	lw	a4,540(s1)
    80004a60:	02f70e63          	beq	a4,a5,80004a9c <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004a64:	0017871b          	addiw	a4,a5,1
    80004a68:	20e4ac23          	sw	a4,536(s1)
    80004a6c:	1ff7f793          	andi	a5,a5,511
    80004a70:	97a6                	add	a5,a5,s1
    80004a72:	0187c783          	lbu	a5,24(a5)
    80004a76:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004a7a:	4685                	li	a3,1
    80004a7c:	fbf40613          	addi	a2,s0,-65
    80004a80:	85ca                	mv	a1,s2
    80004a82:	050a3503          	ld	a0,80(s4)
    80004a86:	ffffd097          	auipc	ra,0xffffd
    80004a8a:	bce080e7          	jalr	-1074(ra) # 80001654 <copyout>
    80004a8e:	01650763          	beq	a0,s6,80004a9c <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004a92:	2985                	addiw	s3,s3,1
    80004a94:	0905                	addi	s2,s2,1
    80004a96:	fd3a91e3          	bne	s5,s3,80004a58 <piperead+0x70>
    80004a9a:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004a9c:	21c48513          	addi	a0,s1,540
    80004aa0:	ffffd097          	auipc	ra,0xffffd
    80004aa4:	600080e7          	jalr	1536(ra) # 800020a0 <wakeup>
  release(&pi->lock);
    80004aa8:	8526                	mv	a0,s1
    80004aaa:	ffffc097          	auipc	ra,0xffffc
    80004aae:	1da080e7          	jalr	474(ra) # 80000c84 <release>
  return i;
}
    80004ab2:	854e                	mv	a0,s3
    80004ab4:	60a6                	ld	ra,72(sp)
    80004ab6:	6406                	ld	s0,64(sp)
    80004ab8:	74e2                	ld	s1,56(sp)
    80004aba:	7942                	ld	s2,48(sp)
    80004abc:	79a2                	ld	s3,40(sp)
    80004abe:	7a02                	ld	s4,32(sp)
    80004ac0:	6ae2                	ld	s5,24(sp)
    80004ac2:	6b42                	ld	s6,16(sp)
    80004ac4:	6161                	addi	sp,sp,80
    80004ac6:	8082                	ret
      release(&pi->lock);
    80004ac8:	8526                	mv	a0,s1
    80004aca:	ffffc097          	auipc	ra,0xffffc
    80004ace:	1ba080e7          	jalr	442(ra) # 80000c84 <release>
      return -1;
    80004ad2:	59fd                	li	s3,-1
    80004ad4:	bff9                	j	80004ab2 <piperead+0xca>

0000000080004ad6 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80004ad6:	1141                	addi	sp,sp,-16
    80004ad8:	e422                	sd	s0,8(sp)
    80004ada:	0800                	addi	s0,sp,16
    80004adc:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004ade:	8905                	andi	a0,a0,1
    80004ae0:	050e                	slli	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    80004ae2:	8b89                	andi	a5,a5,2
    80004ae4:	c399                	beqz	a5,80004aea <flags2perm+0x14>
      perm |= PTE_W;
    80004ae6:	00456513          	ori	a0,a0,4
    return perm;
}
    80004aea:	6422                	ld	s0,8(sp)
    80004aec:	0141                	addi	sp,sp,16
    80004aee:	8082                	ret

0000000080004af0 <exec>:

int
exec(char *path, char **argv)
{
    80004af0:	df010113          	addi	sp,sp,-528
    80004af4:	20113423          	sd	ra,520(sp)
    80004af8:	20813023          	sd	s0,512(sp)
    80004afc:	ffa6                	sd	s1,504(sp)
    80004afe:	fbca                	sd	s2,496(sp)
    80004b00:	f7ce                	sd	s3,488(sp)
    80004b02:	f3d2                	sd	s4,480(sp)
    80004b04:	efd6                	sd	s5,472(sp)
    80004b06:	ebda                	sd	s6,464(sp)
    80004b08:	e7de                	sd	s7,456(sp)
    80004b0a:	e3e2                	sd	s8,448(sp)
    80004b0c:	ff66                	sd	s9,440(sp)
    80004b0e:	fb6a                	sd	s10,432(sp)
    80004b10:	f76e                	sd	s11,424(sp)
    80004b12:	0c00                	addi	s0,sp,528
    80004b14:	892a                	mv	s2,a0
    80004b16:	dea43c23          	sd	a0,-520(s0)
    80004b1a:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004b1e:	ffffd097          	auipc	ra,0xffffd
    80004b22:	e76080e7          	jalr	-394(ra) # 80001994 <myproc>
    80004b26:	84aa                	mv	s1,a0

  begin_op();
    80004b28:	fffff097          	auipc	ra,0xfffff
    80004b2c:	48e080e7          	jalr	1166(ra) # 80003fb6 <begin_op>

  if((ip = namei(path)) == 0){
    80004b30:	854a                	mv	a0,s2
    80004b32:	fffff097          	auipc	ra,0xfffff
    80004b36:	284080e7          	jalr	644(ra) # 80003db6 <namei>
    80004b3a:	c92d                	beqz	a0,80004bac <exec+0xbc>
    80004b3c:	8a2a                	mv	s4,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004b3e:	fffff097          	auipc	ra,0xfffff
    80004b42:	ad2080e7          	jalr	-1326(ra) # 80003610 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004b46:	04000713          	li	a4,64
    80004b4a:	4681                	li	a3,0
    80004b4c:	e5040613          	addi	a2,s0,-432
    80004b50:	4581                	li	a1,0
    80004b52:	8552                	mv	a0,s4
    80004b54:	fffff097          	auipc	ra,0xfffff
    80004b58:	d70080e7          	jalr	-656(ra) # 800038c4 <readi>
    80004b5c:	04000793          	li	a5,64
    80004b60:	00f51a63          	bne	a0,a5,80004b74 <exec+0x84>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80004b64:	e5042703          	lw	a4,-432(s0)
    80004b68:	464c47b7          	lui	a5,0x464c4
    80004b6c:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004b70:	04f70463          	beq	a4,a5,80004bb8 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004b74:	8552                	mv	a0,s4
    80004b76:	fffff097          	auipc	ra,0xfffff
    80004b7a:	cfc080e7          	jalr	-772(ra) # 80003872 <iunlockput>
    end_op();
    80004b7e:	fffff097          	auipc	ra,0xfffff
    80004b82:	4b2080e7          	jalr	1202(ra) # 80004030 <end_op>
  }
  return -1;
    80004b86:	557d                	li	a0,-1
}
    80004b88:	20813083          	ld	ra,520(sp)
    80004b8c:	20013403          	ld	s0,512(sp)
    80004b90:	74fe                	ld	s1,504(sp)
    80004b92:	795e                	ld	s2,496(sp)
    80004b94:	79be                	ld	s3,488(sp)
    80004b96:	7a1e                	ld	s4,480(sp)
    80004b98:	6afe                	ld	s5,472(sp)
    80004b9a:	6b5e                	ld	s6,464(sp)
    80004b9c:	6bbe                	ld	s7,456(sp)
    80004b9e:	6c1e                	ld	s8,448(sp)
    80004ba0:	7cfa                	ld	s9,440(sp)
    80004ba2:	7d5a                	ld	s10,432(sp)
    80004ba4:	7dba                	ld	s11,424(sp)
    80004ba6:	21010113          	addi	sp,sp,528
    80004baa:	8082                	ret
    end_op();
    80004bac:	fffff097          	auipc	ra,0xfffff
    80004bb0:	484080e7          	jalr	1156(ra) # 80004030 <end_op>
    return -1;
    80004bb4:	557d                	li	a0,-1
    80004bb6:	bfc9                	j	80004b88 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004bb8:	8526                	mv	a0,s1
    80004bba:	ffffd097          	auipc	ra,0xffffd
    80004bbe:	e9e080e7          	jalr	-354(ra) # 80001a58 <proc_pagetable>
    80004bc2:	8b2a                	mv	s6,a0
    80004bc4:	d945                	beqz	a0,80004b74 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004bc6:	e7042d03          	lw	s10,-400(s0)
    80004bca:	e8845783          	lhu	a5,-376(s0)
    80004bce:	10078463          	beqz	a5,80004cd6 <exec+0x1e6>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004bd2:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004bd4:	4d81                	li	s11,0
    if(ph.vaddr % PGSIZE != 0)
    80004bd6:	6c85                	lui	s9,0x1
    80004bd8:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004bdc:	def43823          	sd	a5,-528(s0)

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    if(sz - i < PGSIZE)
    80004be0:	6a85                	lui	s5,0x1
    80004be2:	a0b5                	j	80004c4e <exec+0x15e>
      panic("loadseg: address should exist");
    80004be4:	00004517          	auipc	a0,0x4
    80004be8:	b0c50513          	addi	a0,a0,-1268 # 800086f0 <syscalls+0x280>
    80004bec:	ffffc097          	auipc	ra,0xffffc
    80004bf0:	94e080e7          	jalr	-1714(ra) # 8000053a <panic>
    if(sz - i < PGSIZE)
    80004bf4:	2481                	sext.w	s1,s1
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004bf6:	8726                	mv	a4,s1
    80004bf8:	012c06bb          	addw	a3,s8,s2
    80004bfc:	4581                	li	a1,0
    80004bfe:	8552                	mv	a0,s4
    80004c00:	fffff097          	auipc	ra,0xfffff
    80004c04:	cc4080e7          	jalr	-828(ra) # 800038c4 <readi>
    80004c08:	2501                	sext.w	a0,a0
    80004c0a:	24a49863          	bne	s1,a0,80004e5a <exec+0x36a>
  for(i = 0; i < sz; i += PGSIZE){
    80004c0e:	012a893b          	addw	s2,s5,s2
    80004c12:	03397563          	bgeu	s2,s3,80004c3c <exec+0x14c>
    pa = walkaddr(pagetable, va + i);
    80004c16:	02091593          	slli	a1,s2,0x20
    80004c1a:	9181                	srli	a1,a1,0x20
    80004c1c:	95de                	add	a1,a1,s7
    80004c1e:	855a                	mv	a0,s6
    80004c20:	ffffc097          	auipc	ra,0xffffc
    80004c24:	424080e7          	jalr	1060(ra) # 80001044 <walkaddr>
    80004c28:	862a                	mv	a2,a0
    if(pa == 0)
    80004c2a:	dd4d                	beqz	a0,80004be4 <exec+0xf4>
    if(sz - i < PGSIZE)
    80004c2c:	412984bb          	subw	s1,s3,s2
    80004c30:	0004879b          	sext.w	a5,s1
    80004c34:	fcfcf0e3          	bgeu	s9,a5,80004bf4 <exec+0x104>
    80004c38:	84d6                	mv	s1,s5
    80004c3a:	bf6d                	j	80004bf4 <exec+0x104>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80004c3c:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004c40:	2d85                	addiw	s11,s11,1
    80004c42:	038d0d1b          	addiw	s10,s10,56
    80004c46:	e8845783          	lhu	a5,-376(s0)
    80004c4a:	08fdd763          	bge	s11,a5,80004cd8 <exec+0x1e8>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004c4e:	2d01                	sext.w	s10,s10
    80004c50:	03800713          	li	a4,56
    80004c54:	86ea                	mv	a3,s10
    80004c56:	e1840613          	addi	a2,s0,-488
    80004c5a:	4581                	li	a1,0
    80004c5c:	8552                	mv	a0,s4
    80004c5e:	fffff097          	auipc	ra,0xfffff
    80004c62:	c66080e7          	jalr	-922(ra) # 800038c4 <readi>
    80004c66:	03800793          	li	a5,56
    80004c6a:	1ef51663          	bne	a0,a5,80004e56 <exec+0x366>
    if(ph.type != ELF_PROG_LOAD)
    80004c6e:	e1842783          	lw	a5,-488(s0)
    80004c72:	4705                	li	a4,1
    80004c74:	fce796e3          	bne	a5,a4,80004c40 <exec+0x150>
    if(ph.memsz < ph.filesz)
    80004c78:	e4043483          	ld	s1,-448(s0)
    80004c7c:	e3843783          	ld	a5,-456(s0)
    80004c80:	1ef4e863          	bltu	s1,a5,80004e70 <exec+0x380>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004c84:	e2843783          	ld	a5,-472(s0)
    80004c88:	94be                	add	s1,s1,a5
    80004c8a:	1ef4e663          	bltu	s1,a5,80004e76 <exec+0x386>
    if(ph.vaddr % PGSIZE != 0)
    80004c8e:	df043703          	ld	a4,-528(s0)
    80004c92:	8ff9                	and	a5,a5,a4
    80004c94:	1e079463          	bnez	a5,80004e7c <exec+0x38c>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80004c98:	e1c42503          	lw	a0,-484(s0)
    80004c9c:	00000097          	auipc	ra,0x0
    80004ca0:	e3a080e7          	jalr	-454(ra) # 80004ad6 <flags2perm>
    80004ca4:	86aa                	mv	a3,a0
    80004ca6:	8626                	mv	a2,s1
    80004ca8:	85ca                	mv	a1,s2
    80004caa:	855a                	mv	a0,s6
    80004cac:	ffffc097          	auipc	ra,0xffffc
    80004cb0:	74c080e7          	jalr	1868(ra) # 800013f8 <uvmalloc>
    80004cb4:	e0a43423          	sd	a0,-504(s0)
    80004cb8:	1c050563          	beqz	a0,80004e82 <exec+0x392>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80004cbc:	e2843b83          	ld	s7,-472(s0)
    80004cc0:	e2042c03          	lw	s8,-480(s0)
    80004cc4:	e3842983          	lw	s3,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80004cc8:	00098463          	beqz	s3,80004cd0 <exec+0x1e0>
    80004ccc:	4901                	li	s2,0
    80004cce:	b7a1                	j	80004c16 <exec+0x126>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80004cd0:	e0843903          	ld	s2,-504(s0)
    80004cd4:	b7b5                	j	80004c40 <exec+0x150>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004cd6:	4901                	li	s2,0
  iunlockput(ip);
    80004cd8:	8552                	mv	a0,s4
    80004cda:	fffff097          	auipc	ra,0xfffff
    80004cde:	b98080e7          	jalr	-1128(ra) # 80003872 <iunlockput>
  end_op();
    80004ce2:	fffff097          	auipc	ra,0xfffff
    80004ce6:	34e080e7          	jalr	846(ra) # 80004030 <end_op>
  p = myproc();
    80004cea:	ffffd097          	auipc	ra,0xffffd
    80004cee:	caa080e7          	jalr	-854(ra) # 80001994 <myproc>
    80004cf2:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004cf4:	04853c83          	ld	s9,72(a0)
  sz = PGROUNDUP(sz);
    80004cf8:	6985                	lui	s3,0x1
    80004cfa:	19fd                	addi	s3,s3,-1 # fff <_entry-0x7ffff001>
    80004cfc:	99ca                	add	s3,s3,s2
    80004cfe:	77fd                	lui	a5,0xfffff
    80004d00:	00f9f9b3          	and	s3,s3,a5
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004d04:	4691                	li	a3,4
    80004d06:	6609                	lui	a2,0x2
    80004d08:	964e                	add	a2,a2,s3
    80004d0a:	85ce                	mv	a1,s3
    80004d0c:	855a                	mv	a0,s6
    80004d0e:	ffffc097          	auipc	ra,0xffffc
    80004d12:	6ea080e7          	jalr	1770(ra) # 800013f8 <uvmalloc>
    80004d16:	892a                	mv	s2,a0
    80004d18:	e0a43423          	sd	a0,-504(s0)
    80004d1c:	e509                	bnez	a0,80004d26 <exec+0x236>
  if(pagetable)
    80004d1e:	e1343423          	sd	s3,-504(s0)
    80004d22:	4a01                	li	s4,0
    80004d24:	aa1d                	j	80004e5a <exec+0x36a>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004d26:	75f9                	lui	a1,0xffffe
    80004d28:	95aa                	add	a1,a1,a0
    80004d2a:	855a                	mv	a0,s6
    80004d2c:	ffffd097          	auipc	ra,0xffffd
    80004d30:	8f6080e7          	jalr	-1802(ra) # 80001622 <uvmclear>
  stackbase = sp - PGSIZE;
    80004d34:	7bfd                	lui	s7,0xfffff
    80004d36:	9bca                	add	s7,s7,s2
  for(argc = 0; argv[argc]; argc++) {
    80004d38:	e0043783          	ld	a5,-512(s0)
    80004d3c:	6388                	ld	a0,0(a5)
    80004d3e:	c52d                	beqz	a0,80004da8 <exec+0x2b8>
    80004d40:	e9040993          	addi	s3,s0,-368
    80004d44:	f9040c13          	addi	s8,s0,-112
    80004d48:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004d4a:	ffffc097          	auipc	ra,0xffffc
    80004d4e:	0fc080e7          	jalr	252(ra) # 80000e46 <strlen>
    80004d52:	0015079b          	addiw	a5,a0,1
    80004d56:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004d5a:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    80004d5e:	13796563          	bltu	s2,s7,80004e88 <exec+0x398>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004d62:	e0043d03          	ld	s10,-512(s0)
    80004d66:	000d3a03          	ld	s4,0(s10)
    80004d6a:	8552                	mv	a0,s4
    80004d6c:	ffffc097          	auipc	ra,0xffffc
    80004d70:	0da080e7          	jalr	218(ra) # 80000e46 <strlen>
    80004d74:	0015069b          	addiw	a3,a0,1
    80004d78:	8652                	mv	a2,s4
    80004d7a:	85ca                	mv	a1,s2
    80004d7c:	855a                	mv	a0,s6
    80004d7e:	ffffd097          	auipc	ra,0xffffd
    80004d82:	8d6080e7          	jalr	-1834(ra) # 80001654 <copyout>
    80004d86:	10054363          	bltz	a0,80004e8c <exec+0x39c>
    ustack[argc] = sp;
    80004d8a:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004d8e:	0485                	addi	s1,s1,1
    80004d90:	008d0793          	addi	a5,s10,8
    80004d94:	e0f43023          	sd	a5,-512(s0)
    80004d98:	008d3503          	ld	a0,8(s10)
    80004d9c:	c909                	beqz	a0,80004dae <exec+0x2be>
    if(argc >= MAXARG)
    80004d9e:	09a1                	addi	s3,s3,8
    80004da0:	fb8995e3          	bne	s3,s8,80004d4a <exec+0x25a>
  ip = 0;
    80004da4:	4a01                	li	s4,0
    80004da6:	a855                	j	80004e5a <exec+0x36a>
  sp = sz;
    80004da8:	e0843903          	ld	s2,-504(s0)
  for(argc = 0; argv[argc]; argc++) {
    80004dac:	4481                	li	s1,0
  ustack[argc] = 0;
    80004dae:	00349793          	slli	a5,s1,0x3
    80004db2:	f9078793          	addi	a5,a5,-112 # ffffffffffffef90 <end+0xffffffff7ffdd230>
    80004db6:	97a2                	add	a5,a5,s0
    80004db8:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    80004dbc:	00148693          	addi	a3,s1,1
    80004dc0:	068e                	slli	a3,a3,0x3
    80004dc2:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004dc6:	ff097913          	andi	s2,s2,-16
  sz = sz1;
    80004dca:	e0843983          	ld	s3,-504(s0)
  if(sp < stackbase)
    80004dce:	f57968e3          	bltu	s2,s7,80004d1e <exec+0x22e>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004dd2:	e9040613          	addi	a2,s0,-368
    80004dd6:	85ca                	mv	a1,s2
    80004dd8:	855a                	mv	a0,s6
    80004dda:	ffffd097          	auipc	ra,0xffffd
    80004dde:	87a080e7          	jalr	-1926(ra) # 80001654 <copyout>
    80004de2:	0a054763          	bltz	a0,80004e90 <exec+0x3a0>
  p->trapframe->a1 = sp;
    80004de6:	058ab783          	ld	a5,88(s5) # 1058 <_entry-0x7fffefa8>
    80004dea:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004dee:	df843783          	ld	a5,-520(s0)
    80004df2:	0007c703          	lbu	a4,0(a5)
    80004df6:	cf11                	beqz	a4,80004e12 <exec+0x322>
    80004df8:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004dfa:	02f00693          	li	a3,47
    80004dfe:	a039                	j	80004e0c <exec+0x31c>
      last = s+1;
    80004e00:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80004e04:	0785                	addi	a5,a5,1
    80004e06:	fff7c703          	lbu	a4,-1(a5)
    80004e0a:	c701                	beqz	a4,80004e12 <exec+0x322>
    if(*s == '/')
    80004e0c:	fed71ce3          	bne	a4,a3,80004e04 <exec+0x314>
    80004e10:	bfc5                	j	80004e00 <exec+0x310>
  safestrcpy(p->name, last, sizeof(p->name));
    80004e12:	4641                	li	a2,16
    80004e14:	df843583          	ld	a1,-520(s0)
    80004e18:	158a8513          	addi	a0,s5,344
    80004e1c:	ffffc097          	auipc	ra,0xffffc
    80004e20:	ff8080e7          	jalr	-8(ra) # 80000e14 <safestrcpy>
  oldpagetable = p->pagetable;
    80004e24:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80004e28:	056ab823          	sd	s6,80(s5)
  p->sz = sz;
    80004e2c:	e0843783          	ld	a5,-504(s0)
    80004e30:	04fab423          	sd	a5,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004e34:	058ab783          	ld	a5,88(s5)
    80004e38:	e6843703          	ld	a4,-408(s0)
    80004e3c:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004e3e:	058ab783          	ld	a5,88(s5)
    80004e42:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004e46:	85e6                	mv	a1,s9
    80004e48:	ffffd097          	auipc	ra,0xffffd
    80004e4c:	cac080e7          	jalr	-852(ra) # 80001af4 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004e50:	0004851b          	sext.w	a0,s1
    80004e54:	bb15                	j	80004b88 <exec+0x98>
    80004e56:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80004e5a:	e0843583          	ld	a1,-504(s0)
    80004e5e:	855a                	mv	a0,s6
    80004e60:	ffffd097          	auipc	ra,0xffffd
    80004e64:	c94080e7          	jalr	-876(ra) # 80001af4 <proc_freepagetable>
  return -1;
    80004e68:	557d                	li	a0,-1
  if(ip){
    80004e6a:	d00a0fe3          	beqz	s4,80004b88 <exec+0x98>
    80004e6e:	b319                	j	80004b74 <exec+0x84>
    80004e70:	e1243423          	sd	s2,-504(s0)
    80004e74:	b7dd                	j	80004e5a <exec+0x36a>
    80004e76:	e1243423          	sd	s2,-504(s0)
    80004e7a:	b7c5                	j	80004e5a <exec+0x36a>
    80004e7c:	e1243423          	sd	s2,-504(s0)
    80004e80:	bfe9                	j	80004e5a <exec+0x36a>
    80004e82:	e1243423          	sd	s2,-504(s0)
    80004e86:	bfd1                	j	80004e5a <exec+0x36a>
  ip = 0;
    80004e88:	4a01                	li	s4,0
    80004e8a:	bfc1                	j	80004e5a <exec+0x36a>
    80004e8c:	4a01                	li	s4,0
  if(pagetable)
    80004e8e:	b7f1                	j	80004e5a <exec+0x36a>
  sz = sz1;
    80004e90:	e0843983          	ld	s3,-504(s0)
    80004e94:	b569                	j	80004d1e <exec+0x22e>

0000000080004e96 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80004e96:	7179                	addi	sp,sp,-48
    80004e98:	f406                	sd	ra,40(sp)
    80004e9a:	f022                	sd	s0,32(sp)
    80004e9c:	ec26                	sd	s1,24(sp)
    80004e9e:	e84a                	sd	s2,16(sp)
    80004ea0:	1800                	addi	s0,sp,48
    80004ea2:	892e                	mv	s2,a1
    80004ea4:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    80004ea6:	fdc40593          	addi	a1,s0,-36
    80004eaa:	ffffe097          	auipc	ra,0xffffe
    80004eae:	c04080e7          	jalr	-1020(ra) # 80002aae <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80004eb2:	fdc42703          	lw	a4,-36(s0)
    80004eb6:	47bd                	li	a5,15
    80004eb8:	02e7eb63          	bltu	a5,a4,80004eee <argfd+0x58>
    80004ebc:	ffffd097          	auipc	ra,0xffffd
    80004ec0:	ad8080e7          	jalr	-1320(ra) # 80001994 <myproc>
    80004ec4:	fdc42703          	lw	a4,-36(s0)
    80004ec8:	01a70793          	addi	a5,a4,26
    80004ecc:	078e                	slli	a5,a5,0x3
    80004ece:	953e                	add	a0,a0,a5
    80004ed0:	611c                	ld	a5,0(a0)
    80004ed2:	c385                	beqz	a5,80004ef2 <argfd+0x5c>
    return -1;
  if(pfd)
    80004ed4:	00090463          	beqz	s2,80004edc <argfd+0x46>
    *pfd = fd;
    80004ed8:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80004edc:	4501                	li	a0,0
  if(pf)
    80004ede:	c091                	beqz	s1,80004ee2 <argfd+0x4c>
    *pf = f;
    80004ee0:	e09c                	sd	a5,0(s1)
}
    80004ee2:	70a2                	ld	ra,40(sp)
    80004ee4:	7402                	ld	s0,32(sp)
    80004ee6:	64e2                	ld	s1,24(sp)
    80004ee8:	6942                	ld	s2,16(sp)
    80004eea:	6145                	addi	sp,sp,48
    80004eec:	8082                	ret
    return -1;
    80004eee:	557d                	li	a0,-1
    80004ef0:	bfcd                	j	80004ee2 <argfd+0x4c>
    80004ef2:	557d                	li	a0,-1
    80004ef4:	b7fd                	j	80004ee2 <argfd+0x4c>

0000000080004ef6 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80004ef6:	1101                	addi	sp,sp,-32
    80004ef8:	ec06                	sd	ra,24(sp)
    80004efa:	e822                	sd	s0,16(sp)
    80004efc:	e426                	sd	s1,8(sp)
    80004efe:	1000                	addi	s0,sp,32
    80004f00:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80004f02:	ffffd097          	auipc	ra,0xffffd
    80004f06:	a92080e7          	jalr	-1390(ra) # 80001994 <myproc>
    80004f0a:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80004f0c:	0d050793          	addi	a5,a0,208
    80004f10:	4501                	li	a0,0
    80004f12:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80004f14:	6398                	ld	a4,0(a5)
    80004f16:	cb19                	beqz	a4,80004f2c <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80004f18:	2505                	addiw	a0,a0,1
    80004f1a:	07a1                	addi	a5,a5,8
    80004f1c:	fed51ce3          	bne	a0,a3,80004f14 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80004f20:	557d                	li	a0,-1
}
    80004f22:	60e2                	ld	ra,24(sp)
    80004f24:	6442                	ld	s0,16(sp)
    80004f26:	64a2                	ld	s1,8(sp)
    80004f28:	6105                	addi	sp,sp,32
    80004f2a:	8082                	ret
      p->ofile[fd] = f;
    80004f2c:	01a50793          	addi	a5,a0,26
    80004f30:	078e                	slli	a5,a5,0x3
    80004f32:	963e                	add	a2,a2,a5
    80004f34:	e204                	sd	s1,0(a2)
      return fd;
    80004f36:	b7f5                	j	80004f22 <fdalloc+0x2c>

0000000080004f38 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80004f38:	715d                	addi	sp,sp,-80
    80004f3a:	e486                	sd	ra,72(sp)
    80004f3c:	e0a2                	sd	s0,64(sp)
    80004f3e:	fc26                	sd	s1,56(sp)
    80004f40:	f84a                	sd	s2,48(sp)
    80004f42:	f44e                	sd	s3,40(sp)
    80004f44:	f052                	sd	s4,32(sp)
    80004f46:	ec56                	sd	s5,24(sp)
    80004f48:	e85a                	sd	s6,16(sp)
    80004f4a:	0880                	addi	s0,sp,80
    80004f4c:	8b2e                	mv	s6,a1
    80004f4e:	89b2                	mv	s3,a2
    80004f50:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80004f52:	fb040593          	addi	a1,s0,-80
    80004f56:	fffff097          	auipc	ra,0xfffff
    80004f5a:	e7e080e7          	jalr	-386(ra) # 80003dd4 <nameiparent>
    80004f5e:	84aa                	mv	s1,a0
    80004f60:	14050b63          	beqz	a0,800050b6 <create+0x17e>
    return 0;

  ilock(dp);
    80004f64:	ffffe097          	auipc	ra,0xffffe
    80004f68:	6ac080e7          	jalr	1708(ra) # 80003610 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80004f6c:	4601                	li	a2,0
    80004f6e:	fb040593          	addi	a1,s0,-80
    80004f72:	8526                	mv	a0,s1
    80004f74:	fffff097          	auipc	ra,0xfffff
    80004f78:	b80080e7          	jalr	-1152(ra) # 80003af4 <dirlookup>
    80004f7c:	8aaa                	mv	s5,a0
    80004f7e:	c921                	beqz	a0,80004fce <create+0x96>
    iunlockput(dp);
    80004f80:	8526                	mv	a0,s1
    80004f82:	fffff097          	auipc	ra,0xfffff
    80004f86:	8f0080e7          	jalr	-1808(ra) # 80003872 <iunlockput>
    ilock(ip);
    80004f8a:	8556                	mv	a0,s5
    80004f8c:	ffffe097          	auipc	ra,0xffffe
    80004f90:	684080e7          	jalr	1668(ra) # 80003610 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80004f94:	4789                	li	a5,2
    80004f96:	02fb1563          	bne	s6,a5,80004fc0 <create+0x88>
    80004f9a:	044ad783          	lhu	a5,68(s5)
    80004f9e:	37f9                	addiw	a5,a5,-2
    80004fa0:	17c2                	slli	a5,a5,0x30
    80004fa2:	93c1                	srli	a5,a5,0x30
    80004fa4:	4705                	li	a4,1
    80004fa6:	00f76d63          	bltu	a4,a5,80004fc0 <create+0x88>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80004faa:	8556                	mv	a0,s5
    80004fac:	60a6                	ld	ra,72(sp)
    80004fae:	6406                	ld	s0,64(sp)
    80004fb0:	74e2                	ld	s1,56(sp)
    80004fb2:	7942                	ld	s2,48(sp)
    80004fb4:	79a2                	ld	s3,40(sp)
    80004fb6:	7a02                	ld	s4,32(sp)
    80004fb8:	6ae2                	ld	s5,24(sp)
    80004fba:	6b42                	ld	s6,16(sp)
    80004fbc:	6161                	addi	sp,sp,80
    80004fbe:	8082                	ret
    iunlockput(ip);
    80004fc0:	8556                	mv	a0,s5
    80004fc2:	fffff097          	auipc	ra,0xfffff
    80004fc6:	8b0080e7          	jalr	-1872(ra) # 80003872 <iunlockput>
    return 0;
    80004fca:	4a81                	li	s5,0
    80004fcc:	bff9                	j	80004faa <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0){
    80004fce:	85da                	mv	a1,s6
    80004fd0:	4088                	lw	a0,0(s1)
    80004fd2:	ffffe097          	auipc	ra,0xffffe
    80004fd6:	4a6080e7          	jalr	1190(ra) # 80003478 <ialloc>
    80004fda:	8a2a                	mv	s4,a0
    80004fdc:	c529                	beqz	a0,80005026 <create+0xee>
  ilock(ip);
    80004fde:	ffffe097          	auipc	ra,0xffffe
    80004fe2:	632080e7          	jalr	1586(ra) # 80003610 <ilock>
  ip->major = major;
    80004fe6:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80004fea:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    80004fee:	4905                	li	s2,1
    80004ff0:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    80004ff4:	8552                	mv	a0,s4
    80004ff6:	ffffe097          	auipc	ra,0xffffe
    80004ffa:	54e080e7          	jalr	1358(ra) # 80003544 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80004ffe:	032b0b63          	beq	s6,s2,80005034 <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    80005002:	004a2603          	lw	a2,4(s4)
    80005006:	fb040593          	addi	a1,s0,-80
    8000500a:	8526                	mv	a0,s1
    8000500c:	fffff097          	auipc	ra,0xfffff
    80005010:	cf8080e7          	jalr	-776(ra) # 80003d04 <dirlink>
    80005014:	06054f63          	bltz	a0,80005092 <create+0x15a>
  iunlockput(dp);
    80005018:	8526                	mv	a0,s1
    8000501a:	fffff097          	auipc	ra,0xfffff
    8000501e:	858080e7          	jalr	-1960(ra) # 80003872 <iunlockput>
  return ip;
    80005022:	8ad2                	mv	s5,s4
    80005024:	b759                	j	80004faa <create+0x72>
    iunlockput(dp);
    80005026:	8526                	mv	a0,s1
    80005028:	fffff097          	auipc	ra,0xfffff
    8000502c:	84a080e7          	jalr	-1974(ra) # 80003872 <iunlockput>
    return 0;
    80005030:	8ad2                	mv	s5,s4
    80005032:	bfa5                	j	80004faa <create+0x72>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005034:	004a2603          	lw	a2,4(s4)
    80005038:	00003597          	auipc	a1,0x3
    8000503c:	6d858593          	addi	a1,a1,1752 # 80008710 <syscalls+0x2a0>
    80005040:	8552                	mv	a0,s4
    80005042:	fffff097          	auipc	ra,0xfffff
    80005046:	cc2080e7          	jalr	-830(ra) # 80003d04 <dirlink>
    8000504a:	04054463          	bltz	a0,80005092 <create+0x15a>
    8000504e:	40d0                	lw	a2,4(s1)
    80005050:	00003597          	auipc	a1,0x3
    80005054:	6c858593          	addi	a1,a1,1736 # 80008718 <syscalls+0x2a8>
    80005058:	8552                	mv	a0,s4
    8000505a:	fffff097          	auipc	ra,0xfffff
    8000505e:	caa080e7          	jalr	-854(ra) # 80003d04 <dirlink>
    80005062:	02054863          	bltz	a0,80005092 <create+0x15a>
  if(dirlink(dp, name, ip->inum) < 0)
    80005066:	004a2603          	lw	a2,4(s4)
    8000506a:	fb040593          	addi	a1,s0,-80
    8000506e:	8526                	mv	a0,s1
    80005070:	fffff097          	auipc	ra,0xfffff
    80005074:	c94080e7          	jalr	-876(ra) # 80003d04 <dirlink>
    80005078:	00054d63          	bltz	a0,80005092 <create+0x15a>
    dp->nlink++;  // for ".."
    8000507c:	04a4d783          	lhu	a5,74(s1)
    80005080:	2785                	addiw	a5,a5,1
    80005082:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005086:	8526                	mv	a0,s1
    80005088:	ffffe097          	auipc	ra,0xffffe
    8000508c:	4bc080e7          	jalr	1212(ra) # 80003544 <iupdate>
    80005090:	b761                	j	80005018 <create+0xe0>
  ip->nlink = 0;
    80005092:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80005096:	8552                	mv	a0,s4
    80005098:	ffffe097          	auipc	ra,0xffffe
    8000509c:	4ac080e7          	jalr	1196(ra) # 80003544 <iupdate>
  iunlockput(ip);
    800050a0:	8552                	mv	a0,s4
    800050a2:	ffffe097          	auipc	ra,0xffffe
    800050a6:	7d0080e7          	jalr	2000(ra) # 80003872 <iunlockput>
  iunlockput(dp);
    800050aa:	8526                	mv	a0,s1
    800050ac:	ffffe097          	auipc	ra,0xffffe
    800050b0:	7c6080e7          	jalr	1990(ra) # 80003872 <iunlockput>
  return 0;
    800050b4:	bddd                	j	80004faa <create+0x72>
    return 0;
    800050b6:	8aaa                	mv	s5,a0
    800050b8:	bdcd                	j	80004faa <create+0x72>

00000000800050ba <sys_dup>:
{
    800050ba:	7179                	addi	sp,sp,-48
    800050bc:	f406                	sd	ra,40(sp)
    800050be:	f022                	sd	s0,32(sp)
    800050c0:	ec26                	sd	s1,24(sp)
    800050c2:	e84a                	sd	s2,16(sp)
    800050c4:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800050c6:	fd840613          	addi	a2,s0,-40
    800050ca:	4581                	li	a1,0
    800050cc:	4501                	li	a0,0
    800050ce:	00000097          	auipc	ra,0x0
    800050d2:	dc8080e7          	jalr	-568(ra) # 80004e96 <argfd>
    return -1;
    800050d6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800050d8:	02054363          	bltz	a0,800050fe <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    800050dc:	fd843903          	ld	s2,-40(s0)
    800050e0:	854a                	mv	a0,s2
    800050e2:	00000097          	auipc	ra,0x0
    800050e6:	e14080e7          	jalr	-492(ra) # 80004ef6 <fdalloc>
    800050ea:	84aa                	mv	s1,a0
    return -1;
    800050ec:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800050ee:	00054863          	bltz	a0,800050fe <sys_dup+0x44>
  filedup(f);
    800050f2:	854a                	mv	a0,s2
    800050f4:	fffff097          	auipc	ra,0xfffff
    800050f8:	334080e7          	jalr	820(ra) # 80004428 <filedup>
  return fd;
    800050fc:	87a6                	mv	a5,s1
}
    800050fe:	853e                	mv	a0,a5
    80005100:	70a2                	ld	ra,40(sp)
    80005102:	7402                	ld	s0,32(sp)
    80005104:	64e2                	ld	s1,24(sp)
    80005106:	6942                	ld	s2,16(sp)
    80005108:	6145                	addi	sp,sp,48
    8000510a:	8082                	ret

000000008000510c <sys_read>:
{
    8000510c:	7179                	addi	sp,sp,-48
    8000510e:	f406                	sd	ra,40(sp)
    80005110:	f022                	sd	s0,32(sp)
    80005112:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005114:	fd840593          	addi	a1,s0,-40
    80005118:	4505                	li	a0,1
    8000511a:	ffffe097          	auipc	ra,0xffffe
    8000511e:	9b4080e7          	jalr	-1612(ra) # 80002ace <argaddr>
  argint(2, &n);
    80005122:	fe440593          	addi	a1,s0,-28
    80005126:	4509                	li	a0,2
    80005128:	ffffe097          	auipc	ra,0xffffe
    8000512c:	986080e7          	jalr	-1658(ra) # 80002aae <argint>
  if(argfd(0, 0, &f) < 0)
    80005130:	fe840613          	addi	a2,s0,-24
    80005134:	4581                	li	a1,0
    80005136:	4501                	li	a0,0
    80005138:	00000097          	auipc	ra,0x0
    8000513c:	d5e080e7          	jalr	-674(ra) # 80004e96 <argfd>
    80005140:	87aa                	mv	a5,a0
    return -1;
    80005142:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005144:	0007cc63          	bltz	a5,8000515c <sys_read+0x50>
  return fileread(f, p, n);
    80005148:	fe442603          	lw	a2,-28(s0)
    8000514c:	fd843583          	ld	a1,-40(s0)
    80005150:	fe843503          	ld	a0,-24(s0)
    80005154:	fffff097          	auipc	ra,0xfffff
    80005158:	460080e7          	jalr	1120(ra) # 800045b4 <fileread>
}
    8000515c:	70a2                	ld	ra,40(sp)
    8000515e:	7402                	ld	s0,32(sp)
    80005160:	6145                	addi	sp,sp,48
    80005162:	8082                	ret

0000000080005164 <sys_write>:
{
    80005164:	7179                	addi	sp,sp,-48
    80005166:	f406                	sd	ra,40(sp)
    80005168:	f022                	sd	s0,32(sp)
    8000516a:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    8000516c:	fd840593          	addi	a1,s0,-40
    80005170:	4505                	li	a0,1
    80005172:	ffffe097          	auipc	ra,0xffffe
    80005176:	95c080e7          	jalr	-1700(ra) # 80002ace <argaddr>
  argint(2, &n);
    8000517a:	fe440593          	addi	a1,s0,-28
    8000517e:	4509                	li	a0,2
    80005180:	ffffe097          	auipc	ra,0xffffe
    80005184:	92e080e7          	jalr	-1746(ra) # 80002aae <argint>
  if(argfd(0, 0, &f) < 0)
    80005188:	fe840613          	addi	a2,s0,-24
    8000518c:	4581                	li	a1,0
    8000518e:	4501                	li	a0,0
    80005190:	00000097          	auipc	ra,0x0
    80005194:	d06080e7          	jalr	-762(ra) # 80004e96 <argfd>
    80005198:	87aa                	mv	a5,a0
    return -1;
    8000519a:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    8000519c:	0007cc63          	bltz	a5,800051b4 <sys_write+0x50>
  return filewrite(f, p, n);
    800051a0:	fe442603          	lw	a2,-28(s0)
    800051a4:	fd843583          	ld	a1,-40(s0)
    800051a8:	fe843503          	ld	a0,-24(s0)
    800051ac:	fffff097          	auipc	ra,0xfffff
    800051b0:	4ca080e7          	jalr	1226(ra) # 80004676 <filewrite>
}
    800051b4:	70a2                	ld	ra,40(sp)
    800051b6:	7402                	ld	s0,32(sp)
    800051b8:	6145                	addi	sp,sp,48
    800051ba:	8082                	ret

00000000800051bc <sys_close>:
{
    800051bc:	1101                	addi	sp,sp,-32
    800051be:	ec06                	sd	ra,24(sp)
    800051c0:	e822                	sd	s0,16(sp)
    800051c2:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800051c4:	fe040613          	addi	a2,s0,-32
    800051c8:	fec40593          	addi	a1,s0,-20
    800051cc:	4501                	li	a0,0
    800051ce:	00000097          	auipc	ra,0x0
    800051d2:	cc8080e7          	jalr	-824(ra) # 80004e96 <argfd>
    return -1;
    800051d6:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800051d8:	02054463          	bltz	a0,80005200 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800051dc:	ffffc097          	auipc	ra,0xffffc
    800051e0:	7b8080e7          	jalr	1976(ra) # 80001994 <myproc>
    800051e4:	fec42783          	lw	a5,-20(s0)
    800051e8:	07e9                	addi	a5,a5,26
    800051ea:	078e                	slli	a5,a5,0x3
    800051ec:	953e                	add	a0,a0,a5
    800051ee:	00053023          	sd	zero,0(a0)
  fileclose(f);
    800051f2:	fe043503          	ld	a0,-32(s0)
    800051f6:	fffff097          	auipc	ra,0xfffff
    800051fa:	284080e7          	jalr	644(ra) # 8000447a <fileclose>
  return 0;
    800051fe:	4781                	li	a5,0
}
    80005200:	853e                	mv	a0,a5
    80005202:	60e2                	ld	ra,24(sp)
    80005204:	6442                	ld	s0,16(sp)
    80005206:	6105                	addi	sp,sp,32
    80005208:	8082                	ret

000000008000520a <sys_fstat>:
{
    8000520a:	1101                	addi	sp,sp,-32
    8000520c:	ec06                	sd	ra,24(sp)
    8000520e:	e822                	sd	s0,16(sp)
    80005210:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    80005212:	fe040593          	addi	a1,s0,-32
    80005216:	4505                	li	a0,1
    80005218:	ffffe097          	auipc	ra,0xffffe
    8000521c:	8b6080e7          	jalr	-1866(ra) # 80002ace <argaddr>
  if(argfd(0, 0, &f) < 0)
    80005220:	fe840613          	addi	a2,s0,-24
    80005224:	4581                	li	a1,0
    80005226:	4501                	li	a0,0
    80005228:	00000097          	auipc	ra,0x0
    8000522c:	c6e080e7          	jalr	-914(ra) # 80004e96 <argfd>
    80005230:	87aa                	mv	a5,a0
    return -1;
    80005232:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005234:	0007ca63          	bltz	a5,80005248 <sys_fstat+0x3e>
  return filestat(f, st);
    80005238:	fe043583          	ld	a1,-32(s0)
    8000523c:	fe843503          	ld	a0,-24(s0)
    80005240:	fffff097          	auipc	ra,0xfffff
    80005244:	302080e7          	jalr	770(ra) # 80004542 <filestat>
}
    80005248:	60e2                	ld	ra,24(sp)
    8000524a:	6442                	ld	s0,16(sp)
    8000524c:	6105                	addi	sp,sp,32
    8000524e:	8082                	ret

0000000080005250 <sys_link>:
{
    80005250:	7169                	addi	sp,sp,-304
    80005252:	f606                	sd	ra,296(sp)
    80005254:	f222                	sd	s0,288(sp)
    80005256:	ee26                	sd	s1,280(sp)
    80005258:	ea4a                	sd	s2,272(sp)
    8000525a:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000525c:	08000613          	li	a2,128
    80005260:	ed040593          	addi	a1,s0,-304
    80005264:	4501                	li	a0,0
    80005266:	ffffe097          	auipc	ra,0xffffe
    8000526a:	888080e7          	jalr	-1912(ra) # 80002aee <argstr>
    return -1;
    8000526e:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005270:	10054e63          	bltz	a0,8000538c <sys_link+0x13c>
    80005274:	08000613          	li	a2,128
    80005278:	f5040593          	addi	a1,s0,-176
    8000527c:	4505                	li	a0,1
    8000527e:	ffffe097          	auipc	ra,0xffffe
    80005282:	870080e7          	jalr	-1936(ra) # 80002aee <argstr>
    return -1;
    80005286:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005288:	10054263          	bltz	a0,8000538c <sys_link+0x13c>
  begin_op();
    8000528c:	fffff097          	auipc	ra,0xfffff
    80005290:	d2a080e7          	jalr	-726(ra) # 80003fb6 <begin_op>
  if((ip = namei(old)) == 0){
    80005294:	ed040513          	addi	a0,s0,-304
    80005298:	fffff097          	auipc	ra,0xfffff
    8000529c:	b1e080e7          	jalr	-1250(ra) # 80003db6 <namei>
    800052a0:	84aa                	mv	s1,a0
    800052a2:	c551                	beqz	a0,8000532e <sys_link+0xde>
  ilock(ip);
    800052a4:	ffffe097          	auipc	ra,0xffffe
    800052a8:	36c080e7          	jalr	876(ra) # 80003610 <ilock>
  if(ip->type == T_DIR){
    800052ac:	04449703          	lh	a4,68(s1)
    800052b0:	4785                	li	a5,1
    800052b2:	08f70463          	beq	a4,a5,8000533a <sys_link+0xea>
  ip->nlink++;
    800052b6:	04a4d783          	lhu	a5,74(s1)
    800052ba:	2785                	addiw	a5,a5,1
    800052bc:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800052c0:	8526                	mv	a0,s1
    800052c2:	ffffe097          	auipc	ra,0xffffe
    800052c6:	282080e7          	jalr	642(ra) # 80003544 <iupdate>
  iunlock(ip);
    800052ca:	8526                	mv	a0,s1
    800052cc:	ffffe097          	auipc	ra,0xffffe
    800052d0:	406080e7          	jalr	1030(ra) # 800036d2 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800052d4:	fd040593          	addi	a1,s0,-48
    800052d8:	f5040513          	addi	a0,s0,-176
    800052dc:	fffff097          	auipc	ra,0xfffff
    800052e0:	af8080e7          	jalr	-1288(ra) # 80003dd4 <nameiparent>
    800052e4:	892a                	mv	s2,a0
    800052e6:	c935                	beqz	a0,8000535a <sys_link+0x10a>
  ilock(dp);
    800052e8:	ffffe097          	auipc	ra,0xffffe
    800052ec:	328080e7          	jalr	808(ra) # 80003610 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800052f0:	00092703          	lw	a4,0(s2)
    800052f4:	409c                	lw	a5,0(s1)
    800052f6:	04f71d63          	bne	a4,a5,80005350 <sys_link+0x100>
    800052fa:	40d0                	lw	a2,4(s1)
    800052fc:	fd040593          	addi	a1,s0,-48
    80005300:	854a                	mv	a0,s2
    80005302:	fffff097          	auipc	ra,0xfffff
    80005306:	a02080e7          	jalr	-1534(ra) # 80003d04 <dirlink>
    8000530a:	04054363          	bltz	a0,80005350 <sys_link+0x100>
  iunlockput(dp);
    8000530e:	854a                	mv	a0,s2
    80005310:	ffffe097          	auipc	ra,0xffffe
    80005314:	562080e7          	jalr	1378(ra) # 80003872 <iunlockput>
  iput(ip);
    80005318:	8526                	mv	a0,s1
    8000531a:	ffffe097          	auipc	ra,0xffffe
    8000531e:	4b0080e7          	jalr	1200(ra) # 800037ca <iput>
  end_op();
    80005322:	fffff097          	auipc	ra,0xfffff
    80005326:	d0e080e7          	jalr	-754(ra) # 80004030 <end_op>
  return 0;
    8000532a:	4781                	li	a5,0
    8000532c:	a085                	j	8000538c <sys_link+0x13c>
    end_op();
    8000532e:	fffff097          	auipc	ra,0xfffff
    80005332:	d02080e7          	jalr	-766(ra) # 80004030 <end_op>
    return -1;
    80005336:	57fd                	li	a5,-1
    80005338:	a891                	j	8000538c <sys_link+0x13c>
    iunlockput(ip);
    8000533a:	8526                	mv	a0,s1
    8000533c:	ffffe097          	auipc	ra,0xffffe
    80005340:	536080e7          	jalr	1334(ra) # 80003872 <iunlockput>
    end_op();
    80005344:	fffff097          	auipc	ra,0xfffff
    80005348:	cec080e7          	jalr	-788(ra) # 80004030 <end_op>
    return -1;
    8000534c:	57fd                	li	a5,-1
    8000534e:	a83d                	j	8000538c <sys_link+0x13c>
    iunlockput(dp);
    80005350:	854a                	mv	a0,s2
    80005352:	ffffe097          	auipc	ra,0xffffe
    80005356:	520080e7          	jalr	1312(ra) # 80003872 <iunlockput>
  ilock(ip);
    8000535a:	8526                	mv	a0,s1
    8000535c:	ffffe097          	auipc	ra,0xffffe
    80005360:	2b4080e7          	jalr	692(ra) # 80003610 <ilock>
  ip->nlink--;
    80005364:	04a4d783          	lhu	a5,74(s1)
    80005368:	37fd                	addiw	a5,a5,-1
    8000536a:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000536e:	8526                	mv	a0,s1
    80005370:	ffffe097          	auipc	ra,0xffffe
    80005374:	1d4080e7          	jalr	468(ra) # 80003544 <iupdate>
  iunlockput(ip);
    80005378:	8526                	mv	a0,s1
    8000537a:	ffffe097          	auipc	ra,0xffffe
    8000537e:	4f8080e7          	jalr	1272(ra) # 80003872 <iunlockput>
  end_op();
    80005382:	fffff097          	auipc	ra,0xfffff
    80005386:	cae080e7          	jalr	-850(ra) # 80004030 <end_op>
  return -1;
    8000538a:	57fd                	li	a5,-1
}
    8000538c:	853e                	mv	a0,a5
    8000538e:	70b2                	ld	ra,296(sp)
    80005390:	7412                	ld	s0,288(sp)
    80005392:	64f2                	ld	s1,280(sp)
    80005394:	6952                	ld	s2,272(sp)
    80005396:	6155                	addi	sp,sp,304
    80005398:	8082                	ret

000000008000539a <sys_unlink>:
{
    8000539a:	7151                	addi	sp,sp,-240
    8000539c:	f586                	sd	ra,232(sp)
    8000539e:	f1a2                	sd	s0,224(sp)
    800053a0:	eda6                	sd	s1,216(sp)
    800053a2:	e9ca                	sd	s2,208(sp)
    800053a4:	e5ce                	sd	s3,200(sp)
    800053a6:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800053a8:	08000613          	li	a2,128
    800053ac:	f3040593          	addi	a1,s0,-208
    800053b0:	4501                	li	a0,0
    800053b2:	ffffd097          	auipc	ra,0xffffd
    800053b6:	73c080e7          	jalr	1852(ra) # 80002aee <argstr>
    800053ba:	18054163          	bltz	a0,8000553c <sys_unlink+0x1a2>
  begin_op();
    800053be:	fffff097          	auipc	ra,0xfffff
    800053c2:	bf8080e7          	jalr	-1032(ra) # 80003fb6 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800053c6:	fb040593          	addi	a1,s0,-80
    800053ca:	f3040513          	addi	a0,s0,-208
    800053ce:	fffff097          	auipc	ra,0xfffff
    800053d2:	a06080e7          	jalr	-1530(ra) # 80003dd4 <nameiparent>
    800053d6:	84aa                	mv	s1,a0
    800053d8:	c979                	beqz	a0,800054ae <sys_unlink+0x114>
  ilock(dp);
    800053da:	ffffe097          	auipc	ra,0xffffe
    800053de:	236080e7          	jalr	566(ra) # 80003610 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800053e2:	00003597          	auipc	a1,0x3
    800053e6:	32e58593          	addi	a1,a1,814 # 80008710 <syscalls+0x2a0>
    800053ea:	fb040513          	addi	a0,s0,-80
    800053ee:	ffffe097          	auipc	ra,0xffffe
    800053f2:	6ec080e7          	jalr	1772(ra) # 80003ada <namecmp>
    800053f6:	14050a63          	beqz	a0,8000554a <sys_unlink+0x1b0>
    800053fa:	00003597          	auipc	a1,0x3
    800053fe:	31e58593          	addi	a1,a1,798 # 80008718 <syscalls+0x2a8>
    80005402:	fb040513          	addi	a0,s0,-80
    80005406:	ffffe097          	auipc	ra,0xffffe
    8000540a:	6d4080e7          	jalr	1748(ra) # 80003ada <namecmp>
    8000540e:	12050e63          	beqz	a0,8000554a <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005412:	f2c40613          	addi	a2,s0,-212
    80005416:	fb040593          	addi	a1,s0,-80
    8000541a:	8526                	mv	a0,s1
    8000541c:	ffffe097          	auipc	ra,0xffffe
    80005420:	6d8080e7          	jalr	1752(ra) # 80003af4 <dirlookup>
    80005424:	892a                	mv	s2,a0
    80005426:	12050263          	beqz	a0,8000554a <sys_unlink+0x1b0>
  ilock(ip);
    8000542a:	ffffe097          	auipc	ra,0xffffe
    8000542e:	1e6080e7          	jalr	486(ra) # 80003610 <ilock>
  if(ip->nlink < 1)
    80005432:	04a91783          	lh	a5,74(s2)
    80005436:	08f05263          	blez	a5,800054ba <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000543a:	04491703          	lh	a4,68(s2)
    8000543e:	4785                	li	a5,1
    80005440:	08f70563          	beq	a4,a5,800054ca <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005444:	4641                	li	a2,16
    80005446:	4581                	li	a1,0
    80005448:	fc040513          	addi	a0,s0,-64
    8000544c:	ffffc097          	auipc	ra,0xffffc
    80005450:	880080e7          	jalr	-1920(ra) # 80000ccc <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005454:	4741                	li	a4,16
    80005456:	f2c42683          	lw	a3,-212(s0)
    8000545a:	fc040613          	addi	a2,s0,-64
    8000545e:	4581                	li	a1,0
    80005460:	8526                	mv	a0,s1
    80005462:	ffffe097          	auipc	ra,0xffffe
    80005466:	55a080e7          	jalr	1370(ra) # 800039bc <writei>
    8000546a:	47c1                	li	a5,16
    8000546c:	0af51563          	bne	a0,a5,80005516 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005470:	04491703          	lh	a4,68(s2)
    80005474:	4785                	li	a5,1
    80005476:	0af70863          	beq	a4,a5,80005526 <sys_unlink+0x18c>
  iunlockput(dp);
    8000547a:	8526                	mv	a0,s1
    8000547c:	ffffe097          	auipc	ra,0xffffe
    80005480:	3f6080e7          	jalr	1014(ra) # 80003872 <iunlockput>
  ip->nlink--;
    80005484:	04a95783          	lhu	a5,74(s2)
    80005488:	37fd                	addiw	a5,a5,-1
    8000548a:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    8000548e:	854a                	mv	a0,s2
    80005490:	ffffe097          	auipc	ra,0xffffe
    80005494:	0b4080e7          	jalr	180(ra) # 80003544 <iupdate>
  iunlockput(ip);
    80005498:	854a                	mv	a0,s2
    8000549a:	ffffe097          	auipc	ra,0xffffe
    8000549e:	3d8080e7          	jalr	984(ra) # 80003872 <iunlockput>
  end_op();
    800054a2:	fffff097          	auipc	ra,0xfffff
    800054a6:	b8e080e7          	jalr	-1138(ra) # 80004030 <end_op>
  return 0;
    800054aa:	4501                	li	a0,0
    800054ac:	a84d                	j	8000555e <sys_unlink+0x1c4>
    end_op();
    800054ae:	fffff097          	auipc	ra,0xfffff
    800054b2:	b82080e7          	jalr	-1150(ra) # 80004030 <end_op>
    return -1;
    800054b6:	557d                	li	a0,-1
    800054b8:	a05d                	j	8000555e <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800054ba:	00003517          	auipc	a0,0x3
    800054be:	26650513          	addi	a0,a0,614 # 80008720 <syscalls+0x2b0>
    800054c2:	ffffb097          	auipc	ra,0xffffb
    800054c6:	078080e7          	jalr	120(ra) # 8000053a <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800054ca:	04c92703          	lw	a4,76(s2)
    800054ce:	02000793          	li	a5,32
    800054d2:	f6e7f9e3          	bgeu	a5,a4,80005444 <sys_unlink+0xaa>
    800054d6:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800054da:	4741                	li	a4,16
    800054dc:	86ce                	mv	a3,s3
    800054de:	f1840613          	addi	a2,s0,-232
    800054e2:	4581                	li	a1,0
    800054e4:	854a                	mv	a0,s2
    800054e6:	ffffe097          	auipc	ra,0xffffe
    800054ea:	3de080e7          	jalr	990(ra) # 800038c4 <readi>
    800054ee:	47c1                	li	a5,16
    800054f0:	00f51b63          	bne	a0,a5,80005506 <sys_unlink+0x16c>
    if(de.inum != 0)
    800054f4:	f1845783          	lhu	a5,-232(s0)
    800054f8:	e7a1                	bnez	a5,80005540 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800054fa:	29c1                	addiw	s3,s3,16
    800054fc:	04c92783          	lw	a5,76(s2)
    80005500:	fcf9ede3          	bltu	s3,a5,800054da <sys_unlink+0x140>
    80005504:	b781                	j	80005444 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005506:	00003517          	auipc	a0,0x3
    8000550a:	23250513          	addi	a0,a0,562 # 80008738 <syscalls+0x2c8>
    8000550e:	ffffb097          	auipc	ra,0xffffb
    80005512:	02c080e7          	jalr	44(ra) # 8000053a <panic>
    panic("unlink: writei");
    80005516:	00003517          	auipc	a0,0x3
    8000551a:	23a50513          	addi	a0,a0,570 # 80008750 <syscalls+0x2e0>
    8000551e:	ffffb097          	auipc	ra,0xffffb
    80005522:	01c080e7          	jalr	28(ra) # 8000053a <panic>
    dp->nlink--;
    80005526:	04a4d783          	lhu	a5,74(s1)
    8000552a:	37fd                	addiw	a5,a5,-1
    8000552c:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005530:	8526                	mv	a0,s1
    80005532:	ffffe097          	auipc	ra,0xffffe
    80005536:	012080e7          	jalr	18(ra) # 80003544 <iupdate>
    8000553a:	b781                	j	8000547a <sys_unlink+0xe0>
    return -1;
    8000553c:	557d                	li	a0,-1
    8000553e:	a005                	j	8000555e <sys_unlink+0x1c4>
    iunlockput(ip);
    80005540:	854a                	mv	a0,s2
    80005542:	ffffe097          	auipc	ra,0xffffe
    80005546:	330080e7          	jalr	816(ra) # 80003872 <iunlockput>
  iunlockput(dp);
    8000554a:	8526                	mv	a0,s1
    8000554c:	ffffe097          	auipc	ra,0xffffe
    80005550:	326080e7          	jalr	806(ra) # 80003872 <iunlockput>
  end_op();
    80005554:	fffff097          	auipc	ra,0xfffff
    80005558:	adc080e7          	jalr	-1316(ra) # 80004030 <end_op>
  return -1;
    8000555c:	557d                	li	a0,-1
}
    8000555e:	70ae                	ld	ra,232(sp)
    80005560:	740e                	ld	s0,224(sp)
    80005562:	64ee                	ld	s1,216(sp)
    80005564:	694e                	ld	s2,208(sp)
    80005566:	69ae                	ld	s3,200(sp)
    80005568:	616d                	addi	sp,sp,240
    8000556a:	8082                	ret

000000008000556c <sys_open>:

uint64
sys_open(void)
{
    8000556c:	7131                	addi	sp,sp,-192
    8000556e:	fd06                	sd	ra,184(sp)
    80005570:	f922                	sd	s0,176(sp)
    80005572:	f526                	sd	s1,168(sp)
    80005574:	f14a                	sd	s2,160(sp)
    80005576:	ed4e                	sd	s3,152(sp)
    80005578:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    8000557a:	f4c40593          	addi	a1,s0,-180
    8000557e:	4505                	li	a0,1
    80005580:	ffffd097          	auipc	ra,0xffffd
    80005584:	52e080e7          	jalr	1326(ra) # 80002aae <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005588:	08000613          	li	a2,128
    8000558c:	f5040593          	addi	a1,s0,-176
    80005590:	4501                	li	a0,0
    80005592:	ffffd097          	auipc	ra,0xffffd
    80005596:	55c080e7          	jalr	1372(ra) # 80002aee <argstr>
    8000559a:	87aa                	mv	a5,a0
    return -1;
    8000559c:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    8000559e:	0a07c863          	bltz	a5,8000564e <sys_open+0xe2>

  begin_op();
    800055a2:	fffff097          	auipc	ra,0xfffff
    800055a6:	a14080e7          	jalr	-1516(ra) # 80003fb6 <begin_op>

  if(omode & O_CREATE){
    800055aa:	f4c42783          	lw	a5,-180(s0)
    800055ae:	2007f793          	andi	a5,a5,512
    800055b2:	cbdd                	beqz	a5,80005668 <sys_open+0xfc>
    ip = create(path, T_FILE, 0, 0);
    800055b4:	4681                	li	a3,0
    800055b6:	4601                	li	a2,0
    800055b8:	4589                	li	a1,2
    800055ba:	f5040513          	addi	a0,s0,-176
    800055be:	00000097          	auipc	ra,0x0
    800055c2:	97a080e7          	jalr	-1670(ra) # 80004f38 <create>
    800055c6:	84aa                	mv	s1,a0
    if(ip == 0){
    800055c8:	c951                	beqz	a0,8000565c <sys_open+0xf0>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800055ca:	04449703          	lh	a4,68(s1)
    800055ce:	478d                	li	a5,3
    800055d0:	00f71763          	bne	a4,a5,800055de <sys_open+0x72>
    800055d4:	0464d703          	lhu	a4,70(s1)
    800055d8:	47a5                	li	a5,9
    800055da:	0ce7ec63          	bltu	a5,a4,800056b2 <sys_open+0x146>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800055de:	fffff097          	auipc	ra,0xfffff
    800055e2:	de0080e7          	jalr	-544(ra) # 800043be <filealloc>
    800055e6:	892a                	mv	s2,a0
    800055e8:	c56d                	beqz	a0,800056d2 <sys_open+0x166>
    800055ea:	00000097          	auipc	ra,0x0
    800055ee:	90c080e7          	jalr	-1780(ra) # 80004ef6 <fdalloc>
    800055f2:	89aa                	mv	s3,a0
    800055f4:	0c054a63          	bltz	a0,800056c8 <sys_open+0x15c>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800055f8:	04449703          	lh	a4,68(s1)
    800055fc:	478d                	li	a5,3
    800055fe:	0ef70563          	beq	a4,a5,800056e8 <sys_open+0x17c>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005602:	4789                	li	a5,2
    80005604:	00f92023          	sw	a5,0(s2)
    f->off = 0;
    80005608:	02092023          	sw	zero,32(s2)
  }
  f->ip = ip;
    8000560c:	00993c23          	sd	s1,24(s2)
  f->readable = !(omode & O_WRONLY);
    80005610:	f4c42783          	lw	a5,-180(s0)
    80005614:	0017c713          	xori	a4,a5,1
    80005618:	8b05                	andi	a4,a4,1
    8000561a:	00e90423          	sb	a4,8(s2)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    8000561e:	0037f713          	andi	a4,a5,3
    80005622:	00e03733          	snez	a4,a4
    80005626:	00e904a3          	sb	a4,9(s2)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    8000562a:	4007f793          	andi	a5,a5,1024
    8000562e:	c791                	beqz	a5,8000563a <sys_open+0xce>
    80005630:	04449703          	lh	a4,68(s1)
    80005634:	4789                	li	a5,2
    80005636:	0cf70063          	beq	a4,a5,800056f6 <sys_open+0x18a>
    itrunc(ip);
  }

  iunlock(ip);
    8000563a:	8526                	mv	a0,s1
    8000563c:	ffffe097          	auipc	ra,0xffffe
    80005640:	096080e7          	jalr	150(ra) # 800036d2 <iunlock>
  end_op();
    80005644:	fffff097          	auipc	ra,0xfffff
    80005648:	9ec080e7          	jalr	-1556(ra) # 80004030 <end_op>

  return fd;
    8000564c:	854e                	mv	a0,s3
}
    8000564e:	70ea                	ld	ra,184(sp)
    80005650:	744a                	ld	s0,176(sp)
    80005652:	74aa                	ld	s1,168(sp)
    80005654:	790a                	ld	s2,160(sp)
    80005656:	69ea                	ld	s3,152(sp)
    80005658:	6129                	addi	sp,sp,192
    8000565a:	8082                	ret
      end_op();
    8000565c:	fffff097          	auipc	ra,0xfffff
    80005660:	9d4080e7          	jalr	-1580(ra) # 80004030 <end_op>
      return -1;
    80005664:	557d                	li	a0,-1
    80005666:	b7e5                	j	8000564e <sys_open+0xe2>
    if((ip = namei(path)) == 0){
    80005668:	f5040513          	addi	a0,s0,-176
    8000566c:	ffffe097          	auipc	ra,0xffffe
    80005670:	74a080e7          	jalr	1866(ra) # 80003db6 <namei>
    80005674:	84aa                	mv	s1,a0
    80005676:	c905                	beqz	a0,800056a6 <sys_open+0x13a>
    ilock(ip);
    80005678:	ffffe097          	auipc	ra,0xffffe
    8000567c:	f98080e7          	jalr	-104(ra) # 80003610 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005680:	04449703          	lh	a4,68(s1)
    80005684:	4785                	li	a5,1
    80005686:	f4f712e3          	bne	a4,a5,800055ca <sys_open+0x5e>
    8000568a:	f4c42783          	lw	a5,-180(s0)
    8000568e:	dba1                	beqz	a5,800055de <sys_open+0x72>
      iunlockput(ip);
    80005690:	8526                	mv	a0,s1
    80005692:	ffffe097          	auipc	ra,0xffffe
    80005696:	1e0080e7          	jalr	480(ra) # 80003872 <iunlockput>
      end_op();
    8000569a:	fffff097          	auipc	ra,0xfffff
    8000569e:	996080e7          	jalr	-1642(ra) # 80004030 <end_op>
      return -1;
    800056a2:	557d                	li	a0,-1
    800056a4:	b76d                	j	8000564e <sys_open+0xe2>
      end_op();
    800056a6:	fffff097          	auipc	ra,0xfffff
    800056aa:	98a080e7          	jalr	-1654(ra) # 80004030 <end_op>
      return -1;
    800056ae:	557d                	li	a0,-1
    800056b0:	bf79                	j	8000564e <sys_open+0xe2>
    iunlockput(ip);
    800056b2:	8526                	mv	a0,s1
    800056b4:	ffffe097          	auipc	ra,0xffffe
    800056b8:	1be080e7          	jalr	446(ra) # 80003872 <iunlockput>
    end_op();
    800056bc:	fffff097          	auipc	ra,0xfffff
    800056c0:	974080e7          	jalr	-1676(ra) # 80004030 <end_op>
    return -1;
    800056c4:	557d                	li	a0,-1
    800056c6:	b761                	j	8000564e <sys_open+0xe2>
      fileclose(f);
    800056c8:	854a                	mv	a0,s2
    800056ca:	fffff097          	auipc	ra,0xfffff
    800056ce:	db0080e7          	jalr	-592(ra) # 8000447a <fileclose>
    iunlockput(ip);
    800056d2:	8526                	mv	a0,s1
    800056d4:	ffffe097          	auipc	ra,0xffffe
    800056d8:	19e080e7          	jalr	414(ra) # 80003872 <iunlockput>
    end_op();
    800056dc:	fffff097          	auipc	ra,0xfffff
    800056e0:	954080e7          	jalr	-1708(ra) # 80004030 <end_op>
    return -1;
    800056e4:	557d                	li	a0,-1
    800056e6:	b7a5                	j	8000564e <sys_open+0xe2>
    f->type = FD_DEVICE;
    800056e8:	00f92023          	sw	a5,0(s2)
    f->major = ip->major;
    800056ec:	04649783          	lh	a5,70(s1)
    800056f0:	02f91223          	sh	a5,36(s2)
    800056f4:	bf21                	j	8000560c <sys_open+0xa0>
    itrunc(ip);
    800056f6:	8526                	mv	a0,s1
    800056f8:	ffffe097          	auipc	ra,0xffffe
    800056fc:	026080e7          	jalr	38(ra) # 8000371e <itrunc>
    80005700:	bf2d                	j	8000563a <sys_open+0xce>

0000000080005702 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005702:	7175                	addi	sp,sp,-144
    80005704:	e506                	sd	ra,136(sp)
    80005706:	e122                	sd	s0,128(sp)
    80005708:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    8000570a:	fffff097          	auipc	ra,0xfffff
    8000570e:	8ac080e7          	jalr	-1876(ra) # 80003fb6 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005712:	08000613          	li	a2,128
    80005716:	f7040593          	addi	a1,s0,-144
    8000571a:	4501                	li	a0,0
    8000571c:	ffffd097          	auipc	ra,0xffffd
    80005720:	3d2080e7          	jalr	978(ra) # 80002aee <argstr>
    80005724:	02054963          	bltz	a0,80005756 <sys_mkdir+0x54>
    80005728:	4681                	li	a3,0
    8000572a:	4601                	li	a2,0
    8000572c:	4585                	li	a1,1
    8000572e:	f7040513          	addi	a0,s0,-144
    80005732:	00000097          	auipc	ra,0x0
    80005736:	806080e7          	jalr	-2042(ra) # 80004f38 <create>
    8000573a:	cd11                	beqz	a0,80005756 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000573c:	ffffe097          	auipc	ra,0xffffe
    80005740:	136080e7          	jalr	310(ra) # 80003872 <iunlockput>
  end_op();
    80005744:	fffff097          	auipc	ra,0xfffff
    80005748:	8ec080e7          	jalr	-1812(ra) # 80004030 <end_op>
  return 0;
    8000574c:	4501                	li	a0,0
}
    8000574e:	60aa                	ld	ra,136(sp)
    80005750:	640a                	ld	s0,128(sp)
    80005752:	6149                	addi	sp,sp,144
    80005754:	8082                	ret
    end_op();
    80005756:	fffff097          	auipc	ra,0xfffff
    8000575a:	8da080e7          	jalr	-1830(ra) # 80004030 <end_op>
    return -1;
    8000575e:	557d                	li	a0,-1
    80005760:	b7fd                	j	8000574e <sys_mkdir+0x4c>

0000000080005762 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005762:	7135                	addi	sp,sp,-160
    80005764:	ed06                	sd	ra,152(sp)
    80005766:	e922                	sd	s0,144(sp)
    80005768:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    8000576a:	fffff097          	auipc	ra,0xfffff
    8000576e:	84c080e7          	jalr	-1972(ra) # 80003fb6 <begin_op>
  argint(1, &major);
    80005772:	f6c40593          	addi	a1,s0,-148
    80005776:	4505                	li	a0,1
    80005778:	ffffd097          	auipc	ra,0xffffd
    8000577c:	336080e7          	jalr	822(ra) # 80002aae <argint>
  argint(2, &minor);
    80005780:	f6840593          	addi	a1,s0,-152
    80005784:	4509                	li	a0,2
    80005786:	ffffd097          	auipc	ra,0xffffd
    8000578a:	328080e7          	jalr	808(ra) # 80002aae <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000578e:	08000613          	li	a2,128
    80005792:	f7040593          	addi	a1,s0,-144
    80005796:	4501                	li	a0,0
    80005798:	ffffd097          	auipc	ra,0xffffd
    8000579c:	356080e7          	jalr	854(ra) # 80002aee <argstr>
    800057a0:	02054b63          	bltz	a0,800057d6 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    800057a4:	f6841683          	lh	a3,-152(s0)
    800057a8:	f6c41603          	lh	a2,-148(s0)
    800057ac:	458d                	li	a1,3
    800057ae:	f7040513          	addi	a0,s0,-144
    800057b2:	fffff097          	auipc	ra,0xfffff
    800057b6:	786080e7          	jalr	1926(ra) # 80004f38 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800057ba:	cd11                	beqz	a0,800057d6 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800057bc:	ffffe097          	auipc	ra,0xffffe
    800057c0:	0b6080e7          	jalr	182(ra) # 80003872 <iunlockput>
  end_op();
    800057c4:	fffff097          	auipc	ra,0xfffff
    800057c8:	86c080e7          	jalr	-1940(ra) # 80004030 <end_op>
  return 0;
    800057cc:	4501                	li	a0,0
}
    800057ce:	60ea                	ld	ra,152(sp)
    800057d0:	644a                	ld	s0,144(sp)
    800057d2:	610d                	addi	sp,sp,160
    800057d4:	8082                	ret
    end_op();
    800057d6:	fffff097          	auipc	ra,0xfffff
    800057da:	85a080e7          	jalr	-1958(ra) # 80004030 <end_op>
    return -1;
    800057de:	557d                	li	a0,-1
    800057e0:	b7fd                	j	800057ce <sys_mknod+0x6c>

00000000800057e2 <sys_chdir>:

uint64
sys_chdir(void)
{
    800057e2:	7135                	addi	sp,sp,-160
    800057e4:	ed06                	sd	ra,152(sp)
    800057e6:	e922                	sd	s0,144(sp)
    800057e8:	e526                	sd	s1,136(sp)
    800057ea:	e14a                	sd	s2,128(sp)
    800057ec:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    800057ee:	ffffc097          	auipc	ra,0xffffc
    800057f2:	1a6080e7          	jalr	422(ra) # 80001994 <myproc>
    800057f6:	892a                	mv	s2,a0
  
  begin_op();
    800057f8:	ffffe097          	auipc	ra,0xffffe
    800057fc:	7be080e7          	jalr	1982(ra) # 80003fb6 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005800:	08000613          	li	a2,128
    80005804:	f6040593          	addi	a1,s0,-160
    80005808:	4501                	li	a0,0
    8000580a:	ffffd097          	auipc	ra,0xffffd
    8000580e:	2e4080e7          	jalr	740(ra) # 80002aee <argstr>
    80005812:	04054b63          	bltz	a0,80005868 <sys_chdir+0x86>
    80005816:	f6040513          	addi	a0,s0,-160
    8000581a:	ffffe097          	auipc	ra,0xffffe
    8000581e:	59c080e7          	jalr	1436(ra) # 80003db6 <namei>
    80005822:	84aa                	mv	s1,a0
    80005824:	c131                	beqz	a0,80005868 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005826:	ffffe097          	auipc	ra,0xffffe
    8000582a:	dea080e7          	jalr	-534(ra) # 80003610 <ilock>
  if(ip->type != T_DIR){
    8000582e:	04449703          	lh	a4,68(s1)
    80005832:	4785                	li	a5,1
    80005834:	04f71063          	bne	a4,a5,80005874 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005838:	8526                	mv	a0,s1
    8000583a:	ffffe097          	auipc	ra,0xffffe
    8000583e:	e98080e7          	jalr	-360(ra) # 800036d2 <iunlock>
  iput(p->cwd);
    80005842:	15093503          	ld	a0,336(s2)
    80005846:	ffffe097          	auipc	ra,0xffffe
    8000584a:	f84080e7          	jalr	-124(ra) # 800037ca <iput>
  end_op();
    8000584e:	ffffe097          	auipc	ra,0xffffe
    80005852:	7e2080e7          	jalr	2018(ra) # 80004030 <end_op>
  p->cwd = ip;
    80005856:	14993823          	sd	s1,336(s2)
  return 0;
    8000585a:	4501                	li	a0,0
}
    8000585c:	60ea                	ld	ra,152(sp)
    8000585e:	644a                	ld	s0,144(sp)
    80005860:	64aa                	ld	s1,136(sp)
    80005862:	690a                	ld	s2,128(sp)
    80005864:	610d                	addi	sp,sp,160
    80005866:	8082                	ret
    end_op();
    80005868:	ffffe097          	auipc	ra,0xffffe
    8000586c:	7c8080e7          	jalr	1992(ra) # 80004030 <end_op>
    return -1;
    80005870:	557d                	li	a0,-1
    80005872:	b7ed                	j	8000585c <sys_chdir+0x7a>
    iunlockput(ip);
    80005874:	8526                	mv	a0,s1
    80005876:	ffffe097          	auipc	ra,0xffffe
    8000587a:	ffc080e7          	jalr	-4(ra) # 80003872 <iunlockput>
    end_op();
    8000587e:	ffffe097          	auipc	ra,0xffffe
    80005882:	7b2080e7          	jalr	1970(ra) # 80004030 <end_op>
    return -1;
    80005886:	557d                	li	a0,-1
    80005888:	bfd1                	j	8000585c <sys_chdir+0x7a>

000000008000588a <sys_exec>:

uint64
sys_exec(void)
{
    8000588a:	7121                	addi	sp,sp,-448
    8000588c:	ff06                	sd	ra,440(sp)
    8000588e:	fb22                	sd	s0,432(sp)
    80005890:	f726                	sd	s1,424(sp)
    80005892:	f34a                	sd	s2,416(sp)
    80005894:	ef4e                	sd	s3,408(sp)
    80005896:	eb52                	sd	s4,400(sp)
    80005898:	0380                	addi	s0,sp,448
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    8000589a:	e4840593          	addi	a1,s0,-440
    8000589e:	4505                	li	a0,1
    800058a0:	ffffd097          	auipc	ra,0xffffd
    800058a4:	22e080e7          	jalr	558(ra) # 80002ace <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    800058a8:	08000613          	li	a2,128
    800058ac:	f5040593          	addi	a1,s0,-176
    800058b0:	4501                	li	a0,0
    800058b2:	ffffd097          	auipc	ra,0xffffd
    800058b6:	23c080e7          	jalr	572(ra) # 80002aee <argstr>
    800058ba:	87aa                	mv	a5,a0
    return -1;
    800058bc:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    800058be:	0c07c263          	bltz	a5,80005982 <sys_exec+0xf8>
  }
  memset(argv, 0, sizeof(argv));
    800058c2:	10000613          	li	a2,256
    800058c6:	4581                	li	a1,0
    800058c8:	e5040513          	addi	a0,s0,-432
    800058cc:	ffffb097          	auipc	ra,0xffffb
    800058d0:	400080e7          	jalr	1024(ra) # 80000ccc <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    800058d4:	e5040493          	addi	s1,s0,-432
  memset(argv, 0, sizeof(argv));
    800058d8:	89a6                	mv	s3,s1
    800058da:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    800058dc:	02000a13          	li	s4,32
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    800058e0:	00391513          	slli	a0,s2,0x3
    800058e4:	e4040593          	addi	a1,s0,-448
    800058e8:	e4843783          	ld	a5,-440(s0)
    800058ec:	953e                	add	a0,a0,a5
    800058ee:	ffffd097          	auipc	ra,0xffffd
    800058f2:	122080e7          	jalr	290(ra) # 80002a10 <fetchaddr>
    800058f6:	02054a63          	bltz	a0,8000592a <sys_exec+0xa0>
      goto bad;
    }
    if(uarg == 0){
    800058fa:	e4043783          	ld	a5,-448(s0)
    800058fe:	c3b9                	beqz	a5,80005944 <sys_exec+0xba>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005900:	ffffb097          	auipc	ra,0xffffb
    80005904:	1e0080e7          	jalr	480(ra) # 80000ae0 <kalloc>
    80005908:	85aa                	mv	a1,a0
    8000590a:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    8000590e:	cd11                	beqz	a0,8000592a <sys_exec+0xa0>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005910:	6605                	lui	a2,0x1
    80005912:	e4043503          	ld	a0,-448(s0)
    80005916:	ffffd097          	auipc	ra,0xffffd
    8000591a:	14c080e7          	jalr	332(ra) # 80002a62 <fetchstr>
    8000591e:	00054663          	bltz	a0,8000592a <sys_exec+0xa0>
    if(i >= NELEM(argv)){
    80005922:	0905                	addi	s2,s2,1
    80005924:	09a1                	addi	s3,s3,8
    80005926:	fb491de3          	bne	s2,s4,800058e0 <sys_exec+0x56>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000592a:	f5040913          	addi	s2,s0,-176
    8000592e:	6088                	ld	a0,0(s1)
    80005930:	c921                	beqz	a0,80005980 <sys_exec+0xf6>
    kfree(argv[i]);
    80005932:	ffffb097          	auipc	ra,0xffffb
    80005936:	0b0080e7          	jalr	176(ra) # 800009e2 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000593a:	04a1                	addi	s1,s1,8
    8000593c:	ff2499e3          	bne	s1,s2,8000592e <sys_exec+0xa4>
  return -1;
    80005940:	557d                	li	a0,-1
    80005942:	a081                	j	80005982 <sys_exec+0xf8>
      argv[i] = 0;
    80005944:	0009079b          	sext.w	a5,s2
    80005948:	078e                	slli	a5,a5,0x3
    8000594a:	fd078793          	addi	a5,a5,-48
    8000594e:	97a2                	add	a5,a5,s0
    80005950:	e807b023          	sd	zero,-384(a5)
  int ret = exec(path, argv);
    80005954:	e5040593          	addi	a1,s0,-432
    80005958:	f5040513          	addi	a0,s0,-176
    8000595c:	fffff097          	auipc	ra,0xfffff
    80005960:	194080e7          	jalr	404(ra) # 80004af0 <exec>
    80005964:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005966:	f5040993          	addi	s3,s0,-176
    8000596a:	6088                	ld	a0,0(s1)
    8000596c:	c901                	beqz	a0,8000597c <sys_exec+0xf2>
    kfree(argv[i]);
    8000596e:	ffffb097          	auipc	ra,0xffffb
    80005972:	074080e7          	jalr	116(ra) # 800009e2 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005976:	04a1                	addi	s1,s1,8
    80005978:	ff3499e3          	bne	s1,s3,8000596a <sys_exec+0xe0>
  return ret;
    8000597c:	854a                	mv	a0,s2
    8000597e:	a011                	j	80005982 <sys_exec+0xf8>
  return -1;
    80005980:	557d                	li	a0,-1
}
    80005982:	70fa                	ld	ra,440(sp)
    80005984:	745a                	ld	s0,432(sp)
    80005986:	74ba                	ld	s1,424(sp)
    80005988:	791a                	ld	s2,416(sp)
    8000598a:	69fa                	ld	s3,408(sp)
    8000598c:	6a5a                	ld	s4,400(sp)
    8000598e:	6139                	addi	sp,sp,448
    80005990:	8082                	ret

0000000080005992 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005992:	7139                	addi	sp,sp,-64
    80005994:	fc06                	sd	ra,56(sp)
    80005996:	f822                	sd	s0,48(sp)
    80005998:	f426                	sd	s1,40(sp)
    8000599a:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    8000599c:	ffffc097          	auipc	ra,0xffffc
    800059a0:	ff8080e7          	jalr	-8(ra) # 80001994 <myproc>
    800059a4:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    800059a6:	fd840593          	addi	a1,s0,-40
    800059aa:	4501                	li	a0,0
    800059ac:	ffffd097          	auipc	ra,0xffffd
    800059b0:	122080e7          	jalr	290(ra) # 80002ace <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    800059b4:	fc840593          	addi	a1,s0,-56
    800059b8:	fd040513          	addi	a0,s0,-48
    800059bc:	fffff097          	auipc	ra,0xfffff
    800059c0:	dea080e7          	jalr	-534(ra) # 800047a6 <pipealloc>
    return -1;
    800059c4:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    800059c6:	0c054463          	bltz	a0,80005a8e <sys_pipe+0xfc>
  fd0 = -1;
    800059ca:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    800059ce:	fd043503          	ld	a0,-48(s0)
    800059d2:	fffff097          	auipc	ra,0xfffff
    800059d6:	524080e7          	jalr	1316(ra) # 80004ef6 <fdalloc>
    800059da:	fca42223          	sw	a0,-60(s0)
    800059de:	08054b63          	bltz	a0,80005a74 <sys_pipe+0xe2>
    800059e2:	fc843503          	ld	a0,-56(s0)
    800059e6:	fffff097          	auipc	ra,0xfffff
    800059ea:	510080e7          	jalr	1296(ra) # 80004ef6 <fdalloc>
    800059ee:	fca42023          	sw	a0,-64(s0)
    800059f2:	06054863          	bltz	a0,80005a62 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800059f6:	4691                	li	a3,4
    800059f8:	fc440613          	addi	a2,s0,-60
    800059fc:	fd843583          	ld	a1,-40(s0)
    80005a00:	68a8                	ld	a0,80(s1)
    80005a02:	ffffc097          	auipc	ra,0xffffc
    80005a06:	c52080e7          	jalr	-942(ra) # 80001654 <copyout>
    80005a0a:	02054063          	bltz	a0,80005a2a <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005a0e:	4691                	li	a3,4
    80005a10:	fc040613          	addi	a2,s0,-64
    80005a14:	fd843583          	ld	a1,-40(s0)
    80005a18:	0591                	addi	a1,a1,4
    80005a1a:	68a8                	ld	a0,80(s1)
    80005a1c:	ffffc097          	auipc	ra,0xffffc
    80005a20:	c38080e7          	jalr	-968(ra) # 80001654 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005a24:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005a26:	06055463          	bgez	a0,80005a8e <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005a2a:	fc442783          	lw	a5,-60(s0)
    80005a2e:	07e9                	addi	a5,a5,26
    80005a30:	078e                	slli	a5,a5,0x3
    80005a32:	97a6                	add	a5,a5,s1
    80005a34:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005a38:	fc042783          	lw	a5,-64(s0)
    80005a3c:	07e9                	addi	a5,a5,26
    80005a3e:	078e                	slli	a5,a5,0x3
    80005a40:	94be                	add	s1,s1,a5
    80005a42:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005a46:	fd043503          	ld	a0,-48(s0)
    80005a4a:	fffff097          	auipc	ra,0xfffff
    80005a4e:	a30080e7          	jalr	-1488(ra) # 8000447a <fileclose>
    fileclose(wf);
    80005a52:	fc843503          	ld	a0,-56(s0)
    80005a56:	fffff097          	auipc	ra,0xfffff
    80005a5a:	a24080e7          	jalr	-1500(ra) # 8000447a <fileclose>
    return -1;
    80005a5e:	57fd                	li	a5,-1
    80005a60:	a03d                	j	80005a8e <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005a62:	fc442783          	lw	a5,-60(s0)
    80005a66:	0007c763          	bltz	a5,80005a74 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80005a6a:	07e9                	addi	a5,a5,26
    80005a6c:	078e                	slli	a5,a5,0x3
    80005a6e:	97a6                	add	a5,a5,s1
    80005a70:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    80005a74:	fd043503          	ld	a0,-48(s0)
    80005a78:	fffff097          	auipc	ra,0xfffff
    80005a7c:	a02080e7          	jalr	-1534(ra) # 8000447a <fileclose>
    fileclose(wf);
    80005a80:	fc843503          	ld	a0,-56(s0)
    80005a84:	fffff097          	auipc	ra,0xfffff
    80005a88:	9f6080e7          	jalr	-1546(ra) # 8000447a <fileclose>
    return -1;
    80005a8c:	57fd                	li	a5,-1
}
    80005a8e:	853e                	mv	a0,a5
    80005a90:	70e2                	ld	ra,56(sp)
    80005a92:	7442                	ld	s0,48(sp)
    80005a94:	74a2                	ld	s1,40(sp)
    80005a96:	6121                	addi	sp,sp,64
    80005a98:	8082                	ret
    80005a9a:	0000                	unimp
    80005a9c:	0000                	unimp
	...

0000000080005aa0 <kernelvec>:
    80005aa0:	7111                	addi	sp,sp,-256
    80005aa2:	e006                	sd	ra,0(sp)
    80005aa4:	e40a                	sd	sp,8(sp)
    80005aa6:	e80e                	sd	gp,16(sp)
    80005aa8:	ec12                	sd	tp,24(sp)
    80005aaa:	f016                	sd	t0,32(sp)
    80005aac:	f41a                	sd	t1,40(sp)
    80005aae:	f81e                	sd	t2,48(sp)
    80005ab0:	fc22                	sd	s0,56(sp)
    80005ab2:	e0a6                	sd	s1,64(sp)
    80005ab4:	e4aa                	sd	a0,72(sp)
    80005ab6:	e8ae                	sd	a1,80(sp)
    80005ab8:	ecb2                	sd	a2,88(sp)
    80005aba:	f0b6                	sd	a3,96(sp)
    80005abc:	f4ba                	sd	a4,104(sp)
    80005abe:	f8be                	sd	a5,112(sp)
    80005ac0:	fcc2                	sd	a6,120(sp)
    80005ac2:	e146                	sd	a7,128(sp)
    80005ac4:	e54a                	sd	s2,136(sp)
    80005ac6:	e94e                	sd	s3,144(sp)
    80005ac8:	ed52                	sd	s4,152(sp)
    80005aca:	f156                	sd	s5,160(sp)
    80005acc:	f55a                	sd	s6,168(sp)
    80005ace:	f95e                	sd	s7,176(sp)
    80005ad0:	fd62                	sd	s8,184(sp)
    80005ad2:	e1e6                	sd	s9,192(sp)
    80005ad4:	e5ea                	sd	s10,200(sp)
    80005ad6:	e9ee                	sd	s11,208(sp)
    80005ad8:	edf2                	sd	t3,216(sp)
    80005ada:	f1f6                	sd	t4,224(sp)
    80005adc:	f5fa                	sd	t5,232(sp)
    80005ade:	f9fe                	sd	t6,240(sp)
    80005ae0:	dfdfc0ef          	jal	ra,800028dc <kerneltrap>
    80005ae4:	6082                	ld	ra,0(sp)
    80005ae6:	6122                	ld	sp,8(sp)
    80005ae8:	61c2                	ld	gp,16(sp)
    80005aea:	7282                	ld	t0,32(sp)
    80005aec:	7322                	ld	t1,40(sp)
    80005aee:	73c2                	ld	t2,48(sp)
    80005af0:	7462                	ld	s0,56(sp)
    80005af2:	6486                	ld	s1,64(sp)
    80005af4:	6526                	ld	a0,72(sp)
    80005af6:	65c6                	ld	a1,80(sp)
    80005af8:	6666                	ld	a2,88(sp)
    80005afa:	7686                	ld	a3,96(sp)
    80005afc:	7726                	ld	a4,104(sp)
    80005afe:	77c6                	ld	a5,112(sp)
    80005b00:	7866                	ld	a6,120(sp)
    80005b02:	688a                	ld	a7,128(sp)
    80005b04:	692a                	ld	s2,136(sp)
    80005b06:	69ca                	ld	s3,144(sp)
    80005b08:	6a6a                	ld	s4,152(sp)
    80005b0a:	7a8a                	ld	s5,160(sp)
    80005b0c:	7b2a                	ld	s6,168(sp)
    80005b0e:	7bca                	ld	s7,176(sp)
    80005b10:	7c6a                	ld	s8,184(sp)
    80005b12:	6c8e                	ld	s9,192(sp)
    80005b14:	6d2e                	ld	s10,200(sp)
    80005b16:	6dce                	ld	s11,208(sp)
    80005b18:	6e6e                	ld	t3,216(sp)
    80005b1a:	7e8e                	ld	t4,224(sp)
    80005b1c:	7f2e                	ld	t5,232(sp)
    80005b1e:	7fce                	ld	t6,240(sp)
    80005b20:	6111                	addi	sp,sp,256
    80005b22:	10200073          	sret
    80005b26:	00000013          	nop
    80005b2a:	00000013          	nop
    80005b2e:	0001                	nop

0000000080005b30 <timervec>:
    80005b30:	34051573          	csrrw	a0,mscratch,a0
    80005b34:	e10c                	sd	a1,0(a0)
    80005b36:	e510                	sd	a2,8(a0)
    80005b38:	e914                	sd	a3,16(a0)
    80005b3a:	6d0c                	ld	a1,24(a0)
    80005b3c:	7110                	ld	a2,32(a0)
    80005b3e:	6194                	ld	a3,0(a1)
    80005b40:	96b2                	add	a3,a3,a2
    80005b42:	e194                	sd	a3,0(a1)
    80005b44:	4589                	li	a1,2
    80005b46:	14459073          	csrw	sip,a1
    80005b4a:	6914                	ld	a3,16(a0)
    80005b4c:	6510                	ld	a2,8(a0)
    80005b4e:	610c                	ld	a1,0(a0)
    80005b50:	34051573          	csrrw	a0,mscratch,a0
    80005b54:	30200073          	mret
	...

0000000080005b5a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005b5a:	1141                	addi	sp,sp,-16
    80005b5c:	e422                	sd	s0,8(sp)
    80005b5e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005b60:	0c0007b7          	lui	a5,0xc000
    80005b64:	4705                	li	a4,1
    80005b66:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005b68:	c3d8                	sw	a4,4(a5)
}
    80005b6a:	6422                	ld	s0,8(sp)
    80005b6c:	0141                	addi	sp,sp,16
    80005b6e:	8082                	ret

0000000080005b70 <plicinithart>:

void
plicinithart(void)
{
    80005b70:	1141                	addi	sp,sp,-16
    80005b72:	e406                	sd	ra,8(sp)
    80005b74:	e022                	sd	s0,0(sp)
    80005b76:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005b78:	ffffc097          	auipc	ra,0xffffc
    80005b7c:	df0080e7          	jalr	-528(ra) # 80001968 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005b80:	0085171b          	slliw	a4,a0,0x8
    80005b84:	0c0027b7          	lui	a5,0xc002
    80005b88:	97ba                	add	a5,a5,a4
    80005b8a:	40200713          	li	a4,1026
    80005b8e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005b92:	00d5151b          	slliw	a0,a0,0xd
    80005b96:	0c2017b7          	lui	a5,0xc201
    80005b9a:	97aa                	add	a5,a5,a0
    80005b9c:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80005ba0:	60a2                	ld	ra,8(sp)
    80005ba2:	6402                	ld	s0,0(sp)
    80005ba4:	0141                	addi	sp,sp,16
    80005ba6:	8082                	ret

0000000080005ba8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005ba8:	1141                	addi	sp,sp,-16
    80005baa:	e406                	sd	ra,8(sp)
    80005bac:	e022                	sd	s0,0(sp)
    80005bae:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005bb0:	ffffc097          	auipc	ra,0xffffc
    80005bb4:	db8080e7          	jalr	-584(ra) # 80001968 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005bb8:	00d5151b          	slliw	a0,a0,0xd
    80005bbc:	0c2017b7          	lui	a5,0xc201
    80005bc0:	97aa                	add	a5,a5,a0
  return irq;
}
    80005bc2:	43c8                	lw	a0,4(a5)
    80005bc4:	60a2                	ld	ra,8(sp)
    80005bc6:	6402                	ld	s0,0(sp)
    80005bc8:	0141                	addi	sp,sp,16
    80005bca:	8082                	ret

0000000080005bcc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005bcc:	1101                	addi	sp,sp,-32
    80005bce:	ec06                	sd	ra,24(sp)
    80005bd0:	e822                	sd	s0,16(sp)
    80005bd2:	e426                	sd	s1,8(sp)
    80005bd4:	1000                	addi	s0,sp,32
    80005bd6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005bd8:	ffffc097          	auipc	ra,0xffffc
    80005bdc:	d90080e7          	jalr	-624(ra) # 80001968 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005be0:	00d5151b          	slliw	a0,a0,0xd
    80005be4:	0c2017b7          	lui	a5,0xc201
    80005be8:	97aa                	add	a5,a5,a0
    80005bea:	c3c4                	sw	s1,4(a5)
}
    80005bec:	60e2                	ld	ra,24(sp)
    80005bee:	6442                	ld	s0,16(sp)
    80005bf0:	64a2                	ld	s1,8(sp)
    80005bf2:	6105                	addi	sp,sp,32
    80005bf4:	8082                	ret

0000000080005bf6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005bf6:	1141                	addi	sp,sp,-16
    80005bf8:	e406                	sd	ra,8(sp)
    80005bfa:	e022                	sd	s0,0(sp)
    80005bfc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005bfe:	479d                	li	a5,7
    80005c00:	04a7cc63          	blt	a5,a0,80005c58 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80005c04:	0001c797          	auipc	a5,0x1c
    80005c08:	01c78793          	addi	a5,a5,28 # 80021c20 <disk>
    80005c0c:	97aa                	add	a5,a5,a0
    80005c0e:	0187c783          	lbu	a5,24(a5)
    80005c12:	ebb9                	bnez	a5,80005c68 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005c14:	00451693          	slli	a3,a0,0x4
    80005c18:	0001c797          	auipc	a5,0x1c
    80005c1c:	00878793          	addi	a5,a5,8 # 80021c20 <disk>
    80005c20:	6398                	ld	a4,0(a5)
    80005c22:	9736                	add	a4,a4,a3
    80005c24:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    80005c28:	6398                	ld	a4,0(a5)
    80005c2a:	9736                	add	a4,a4,a3
    80005c2c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80005c30:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80005c34:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80005c38:	97aa                	add	a5,a5,a0
    80005c3a:	4705                	li	a4,1
    80005c3c:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    80005c40:	0001c517          	auipc	a0,0x1c
    80005c44:	ff850513          	addi	a0,a0,-8 # 80021c38 <disk+0x18>
    80005c48:	ffffc097          	auipc	ra,0xffffc
    80005c4c:	458080e7          	jalr	1112(ra) # 800020a0 <wakeup>
}
    80005c50:	60a2                	ld	ra,8(sp)
    80005c52:	6402                	ld	s0,0(sp)
    80005c54:	0141                	addi	sp,sp,16
    80005c56:	8082                	ret
    panic("free_desc 1");
    80005c58:	00003517          	auipc	a0,0x3
    80005c5c:	b0850513          	addi	a0,a0,-1272 # 80008760 <syscalls+0x2f0>
    80005c60:	ffffb097          	auipc	ra,0xffffb
    80005c64:	8da080e7          	jalr	-1830(ra) # 8000053a <panic>
    panic("free_desc 2");
    80005c68:	00003517          	auipc	a0,0x3
    80005c6c:	b0850513          	addi	a0,a0,-1272 # 80008770 <syscalls+0x300>
    80005c70:	ffffb097          	auipc	ra,0xffffb
    80005c74:	8ca080e7          	jalr	-1846(ra) # 8000053a <panic>

0000000080005c78 <virtio_disk_init>:
{
    80005c78:	1101                	addi	sp,sp,-32
    80005c7a:	ec06                	sd	ra,24(sp)
    80005c7c:	e822                	sd	s0,16(sp)
    80005c7e:	e426                	sd	s1,8(sp)
    80005c80:	e04a                	sd	s2,0(sp)
    80005c82:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005c84:	00003597          	auipc	a1,0x3
    80005c88:	afc58593          	addi	a1,a1,-1284 # 80008780 <syscalls+0x310>
    80005c8c:	0001c517          	auipc	a0,0x1c
    80005c90:	0bc50513          	addi	a0,a0,188 # 80021d48 <disk+0x128>
    80005c94:	ffffb097          	auipc	ra,0xffffb
    80005c98:	eac080e7          	jalr	-340(ra) # 80000b40 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005c9c:	100017b7          	lui	a5,0x10001
    80005ca0:	4398                	lw	a4,0(a5)
    80005ca2:	2701                	sext.w	a4,a4
    80005ca4:	747277b7          	lui	a5,0x74727
    80005ca8:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005cac:	14f71b63          	bne	a4,a5,80005e02 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005cb0:	100017b7          	lui	a5,0x10001
    80005cb4:	43dc                	lw	a5,4(a5)
    80005cb6:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005cb8:	4709                	li	a4,2
    80005cba:	14e79463          	bne	a5,a4,80005e02 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005cbe:	100017b7          	lui	a5,0x10001
    80005cc2:	479c                	lw	a5,8(a5)
    80005cc4:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005cc6:	12e79e63          	bne	a5,a4,80005e02 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005cca:	100017b7          	lui	a5,0x10001
    80005cce:	47d8                	lw	a4,12(a5)
    80005cd0:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005cd2:	554d47b7          	lui	a5,0x554d4
    80005cd6:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005cda:	12f71463          	bne	a4,a5,80005e02 <virtio_disk_init+0x18a>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005cde:	100017b7          	lui	a5,0x10001
    80005ce2:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ce6:	4705                	li	a4,1
    80005ce8:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005cea:	470d                	li	a4,3
    80005cec:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005cee:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005cf0:	c7ffe6b7          	lui	a3,0xc7ffe
    80005cf4:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fdc9ff>
    80005cf8:	8f75                	and	a4,a4,a3
    80005cfa:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005cfc:	472d                	li	a4,11
    80005cfe:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80005d00:	5bbc                	lw	a5,112(a5)
    80005d02:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80005d06:	8ba1                	andi	a5,a5,8
    80005d08:	10078563          	beqz	a5,80005e12 <virtio_disk_init+0x19a>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005d0c:	100017b7          	lui	a5,0x10001
    80005d10:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80005d14:	43fc                	lw	a5,68(a5)
    80005d16:	2781                	sext.w	a5,a5
    80005d18:	10079563          	bnez	a5,80005e22 <virtio_disk_init+0x1aa>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005d1c:	100017b7          	lui	a5,0x10001
    80005d20:	5bdc                	lw	a5,52(a5)
    80005d22:	2781                	sext.w	a5,a5
  if(max == 0)
    80005d24:	10078763          	beqz	a5,80005e32 <virtio_disk_init+0x1ba>
  if(max < NUM)
    80005d28:	471d                	li	a4,7
    80005d2a:	10f77c63          	bgeu	a4,a5,80005e42 <virtio_disk_init+0x1ca>
  disk.desc = kalloc();
    80005d2e:	ffffb097          	auipc	ra,0xffffb
    80005d32:	db2080e7          	jalr	-590(ra) # 80000ae0 <kalloc>
    80005d36:	0001c497          	auipc	s1,0x1c
    80005d3a:	eea48493          	addi	s1,s1,-278 # 80021c20 <disk>
    80005d3e:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80005d40:	ffffb097          	auipc	ra,0xffffb
    80005d44:	da0080e7          	jalr	-608(ra) # 80000ae0 <kalloc>
    80005d48:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    80005d4a:	ffffb097          	auipc	ra,0xffffb
    80005d4e:	d96080e7          	jalr	-618(ra) # 80000ae0 <kalloc>
    80005d52:	87aa                	mv	a5,a0
    80005d54:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80005d56:	6088                	ld	a0,0(s1)
    80005d58:	cd6d                	beqz	a0,80005e52 <virtio_disk_init+0x1da>
    80005d5a:	0001c717          	auipc	a4,0x1c
    80005d5e:	ece73703          	ld	a4,-306(a4) # 80021c28 <disk+0x8>
    80005d62:	cb65                	beqz	a4,80005e52 <virtio_disk_init+0x1da>
    80005d64:	c7fd                	beqz	a5,80005e52 <virtio_disk_init+0x1da>
  memset(disk.desc, 0, PGSIZE);
    80005d66:	6605                	lui	a2,0x1
    80005d68:	4581                	li	a1,0
    80005d6a:	ffffb097          	auipc	ra,0xffffb
    80005d6e:	f62080e7          	jalr	-158(ra) # 80000ccc <memset>
  memset(disk.avail, 0, PGSIZE);
    80005d72:	0001c497          	auipc	s1,0x1c
    80005d76:	eae48493          	addi	s1,s1,-338 # 80021c20 <disk>
    80005d7a:	6605                	lui	a2,0x1
    80005d7c:	4581                	li	a1,0
    80005d7e:	6488                	ld	a0,8(s1)
    80005d80:	ffffb097          	auipc	ra,0xffffb
    80005d84:	f4c080e7          	jalr	-180(ra) # 80000ccc <memset>
  memset(disk.used, 0, PGSIZE);
    80005d88:	6605                	lui	a2,0x1
    80005d8a:	4581                	li	a1,0
    80005d8c:	6888                	ld	a0,16(s1)
    80005d8e:	ffffb097          	auipc	ra,0xffffb
    80005d92:	f3e080e7          	jalr	-194(ra) # 80000ccc <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005d96:	100017b7          	lui	a5,0x10001
    80005d9a:	4721                	li	a4,8
    80005d9c:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    80005d9e:	4098                	lw	a4,0(s1)
    80005da0:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80005da4:	40d8                	lw	a4,4(s1)
    80005da6:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    80005daa:	6498                	ld	a4,8(s1)
    80005dac:	0007069b          	sext.w	a3,a4
    80005db0:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80005db4:	9701                	srai	a4,a4,0x20
    80005db6:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    80005dba:	6898                	ld	a4,16(s1)
    80005dbc:	0007069b          	sext.w	a3,a4
    80005dc0:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80005dc4:	9701                	srai	a4,a4,0x20
    80005dc6:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    80005dca:	4705                	li	a4,1
    80005dcc:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    80005dce:	00e48c23          	sb	a4,24(s1)
    80005dd2:	00e48ca3          	sb	a4,25(s1)
    80005dd6:	00e48d23          	sb	a4,26(s1)
    80005dda:	00e48da3          	sb	a4,27(s1)
    80005dde:	00e48e23          	sb	a4,28(s1)
    80005de2:	00e48ea3          	sb	a4,29(s1)
    80005de6:	00e48f23          	sb	a4,30(s1)
    80005dea:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80005dee:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80005df2:	0727a823          	sw	s2,112(a5)
}
    80005df6:	60e2                	ld	ra,24(sp)
    80005df8:	6442                	ld	s0,16(sp)
    80005dfa:	64a2                	ld	s1,8(sp)
    80005dfc:	6902                	ld	s2,0(sp)
    80005dfe:	6105                	addi	sp,sp,32
    80005e00:	8082                	ret
    panic("could not find virtio disk");
    80005e02:	00003517          	auipc	a0,0x3
    80005e06:	98e50513          	addi	a0,a0,-1650 # 80008790 <syscalls+0x320>
    80005e0a:	ffffa097          	auipc	ra,0xffffa
    80005e0e:	730080e7          	jalr	1840(ra) # 8000053a <panic>
    panic("virtio disk FEATURES_OK unset");
    80005e12:	00003517          	auipc	a0,0x3
    80005e16:	99e50513          	addi	a0,a0,-1634 # 800087b0 <syscalls+0x340>
    80005e1a:	ffffa097          	auipc	ra,0xffffa
    80005e1e:	720080e7          	jalr	1824(ra) # 8000053a <panic>
    panic("virtio disk should not be ready");
    80005e22:	00003517          	auipc	a0,0x3
    80005e26:	9ae50513          	addi	a0,a0,-1618 # 800087d0 <syscalls+0x360>
    80005e2a:	ffffa097          	auipc	ra,0xffffa
    80005e2e:	710080e7          	jalr	1808(ra) # 8000053a <panic>
    panic("virtio disk has no queue 0");
    80005e32:	00003517          	auipc	a0,0x3
    80005e36:	9be50513          	addi	a0,a0,-1602 # 800087f0 <syscalls+0x380>
    80005e3a:	ffffa097          	auipc	ra,0xffffa
    80005e3e:	700080e7          	jalr	1792(ra) # 8000053a <panic>
    panic("virtio disk max queue too short");
    80005e42:	00003517          	auipc	a0,0x3
    80005e46:	9ce50513          	addi	a0,a0,-1586 # 80008810 <syscalls+0x3a0>
    80005e4a:	ffffa097          	auipc	ra,0xffffa
    80005e4e:	6f0080e7          	jalr	1776(ra) # 8000053a <panic>
    panic("virtio disk kalloc");
    80005e52:	00003517          	auipc	a0,0x3
    80005e56:	9de50513          	addi	a0,a0,-1570 # 80008830 <syscalls+0x3c0>
    80005e5a:	ffffa097          	auipc	ra,0xffffa
    80005e5e:	6e0080e7          	jalr	1760(ra) # 8000053a <panic>

0000000080005e62 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005e62:	7159                	addi	sp,sp,-112
    80005e64:	f486                	sd	ra,104(sp)
    80005e66:	f0a2                	sd	s0,96(sp)
    80005e68:	eca6                	sd	s1,88(sp)
    80005e6a:	e8ca                	sd	s2,80(sp)
    80005e6c:	e4ce                	sd	s3,72(sp)
    80005e6e:	e0d2                	sd	s4,64(sp)
    80005e70:	fc56                	sd	s5,56(sp)
    80005e72:	f85a                	sd	s6,48(sp)
    80005e74:	f45e                	sd	s7,40(sp)
    80005e76:	f062                	sd	s8,32(sp)
    80005e78:	ec66                	sd	s9,24(sp)
    80005e7a:	e86a                	sd	s10,16(sp)
    80005e7c:	1880                	addi	s0,sp,112
    80005e7e:	8a2a                	mv	s4,a0
    80005e80:	8bae                	mv	s7,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80005e82:	00c52c83          	lw	s9,12(a0)
    80005e86:	001c9c9b          	slliw	s9,s9,0x1
    80005e8a:	1c82                	slli	s9,s9,0x20
    80005e8c:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80005e90:	0001c517          	auipc	a0,0x1c
    80005e94:	eb850513          	addi	a0,a0,-328 # 80021d48 <disk+0x128>
    80005e98:	ffffb097          	auipc	ra,0xffffb
    80005e9c:	d38080e7          	jalr	-712(ra) # 80000bd0 <acquire>
  for(int i = 0; i < 3; i++){
    80005ea0:	4901                	li	s2,0
  for(int i = 0; i < NUM; i++){
    80005ea2:	44a1                	li	s1,8
      disk.free[i] = 0;
    80005ea4:	0001cb17          	auipc	s6,0x1c
    80005ea8:	d7cb0b13          	addi	s6,s6,-644 # 80021c20 <disk>
  for(int i = 0; i < 3; i++){
    80005eac:	4a8d                	li	s5,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80005eae:	0001cc17          	auipc	s8,0x1c
    80005eb2:	e9ac0c13          	addi	s8,s8,-358 # 80021d48 <disk+0x128>
    80005eb6:	a095                	j	80005f1a <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    80005eb8:	00fb0733          	add	a4,s6,a5
    80005ebc:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80005ec0:	c11c                	sw	a5,0(a0)
    if(idx[i] < 0){
    80005ec2:	0207c563          	bltz	a5,80005eec <virtio_disk_rw+0x8a>
  for(int i = 0; i < 3; i++){
    80005ec6:	2605                	addiw	a2,a2,1 # 1001 <_entry-0x7fffefff>
    80005ec8:	0591                	addi	a1,a1,4
    80005eca:	05560d63          	beq	a2,s5,80005f24 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    80005ece:	852e                	mv	a0,a1
  for(int i = 0; i < NUM; i++){
    80005ed0:	0001c717          	auipc	a4,0x1c
    80005ed4:	d5070713          	addi	a4,a4,-688 # 80021c20 <disk>
    80005ed8:	87ca                	mv	a5,s2
    if(disk.free[i]){
    80005eda:	01874683          	lbu	a3,24(a4)
    80005ede:	fee9                	bnez	a3,80005eb8 <virtio_disk_rw+0x56>
  for(int i = 0; i < NUM; i++){
    80005ee0:	2785                	addiw	a5,a5,1
    80005ee2:	0705                	addi	a4,a4,1
    80005ee4:	fe979be3          	bne	a5,s1,80005eda <virtio_disk_rw+0x78>
    idx[i] = alloc_desc();
    80005ee8:	57fd                	li	a5,-1
    80005eea:	c11c                	sw	a5,0(a0)
      for(int j = 0; j < i; j++)
    80005eec:	00c05e63          	blez	a2,80005f08 <virtio_disk_rw+0xa6>
    80005ef0:	060a                	slli	a2,a2,0x2
    80005ef2:	01360d33          	add	s10,a2,s3
        free_desc(idx[j]);
    80005ef6:	0009a503          	lw	a0,0(s3)
    80005efa:	00000097          	auipc	ra,0x0
    80005efe:	cfc080e7          	jalr	-772(ra) # 80005bf6 <free_desc>
      for(int j = 0; j < i; j++)
    80005f02:	0991                	addi	s3,s3,4
    80005f04:	ffa999e3          	bne	s3,s10,80005ef6 <virtio_disk_rw+0x94>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80005f08:	85e2                	mv	a1,s8
    80005f0a:	0001c517          	auipc	a0,0x1c
    80005f0e:	d2e50513          	addi	a0,a0,-722 # 80021c38 <disk+0x18>
    80005f12:	ffffc097          	auipc	ra,0xffffc
    80005f16:	12a080e7          	jalr	298(ra) # 8000203c <sleep>
  for(int i = 0; i < 3; i++){
    80005f1a:	f9040993          	addi	s3,s0,-112
{
    80005f1e:	85ce                	mv	a1,s3
  for(int i = 0; i < 3; i++){
    80005f20:	864a                	mv	a2,s2
    80005f22:	b775                	j	80005ece <virtio_disk_rw+0x6c>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80005f24:	f9042503          	lw	a0,-112(s0)
    80005f28:	00a50713          	addi	a4,a0,10
    80005f2c:	0712                	slli	a4,a4,0x4

  if(write)
    80005f2e:	0001c797          	auipc	a5,0x1c
    80005f32:	cf278793          	addi	a5,a5,-782 # 80021c20 <disk>
    80005f36:	00e786b3          	add	a3,a5,a4
    80005f3a:	01703633          	snez	a2,s7
    80005f3e:	c690                	sw	a2,8(a3)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80005f40:	0006a623          	sw	zero,12(a3)
  buf0->sector = sector;
    80005f44:	0196b823          	sd	s9,16(a3)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80005f48:	f6070613          	addi	a2,a4,-160
    80005f4c:	6394                	ld	a3,0(a5)
    80005f4e:	96b2                	add	a3,a3,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80005f50:	00870593          	addi	a1,a4,8
    80005f54:	95be                	add	a1,a1,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    80005f56:	e28c                	sd	a1,0(a3)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80005f58:	0007b803          	ld	a6,0(a5)
    80005f5c:	9642                	add	a2,a2,a6
    80005f5e:	46c1                	li	a3,16
    80005f60:	c614                	sw	a3,8(a2)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80005f62:	4585                	li	a1,1
    80005f64:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[0]].next = idx[1];
    80005f68:	f9442683          	lw	a3,-108(s0)
    80005f6c:	00d61723          	sh	a3,14(a2)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80005f70:	0692                	slli	a3,a3,0x4
    80005f72:	9836                	add	a6,a6,a3
    80005f74:	058a0613          	addi	a2,s4,88
    80005f78:	00c83023          	sd	a2,0(a6)
  disk.desc[idx[1]].len = BSIZE;
    80005f7c:	0007b803          	ld	a6,0(a5)
    80005f80:	96c2                	add	a3,a3,a6
    80005f82:	40000613          	li	a2,1024
    80005f86:	c690                	sw	a2,8(a3)
  if(write)
    80005f88:	001bb613          	seqz	a2,s7
    80005f8c:	0016161b          	slliw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80005f90:	00166613          	ori	a2,a2,1
    80005f94:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    80005f98:	f9842603          	lw	a2,-104(s0)
    80005f9c:	00c69723          	sh	a2,14(a3)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80005fa0:	00250693          	addi	a3,a0,2
    80005fa4:	0692                	slli	a3,a3,0x4
    80005fa6:	96be                	add	a3,a3,a5
    80005fa8:	58fd                	li	a7,-1
    80005faa:	01168823          	sb	a7,16(a3)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80005fae:	0612                	slli	a2,a2,0x4
    80005fb0:	9832                	add	a6,a6,a2
    80005fb2:	f9070713          	addi	a4,a4,-112
    80005fb6:	973e                	add	a4,a4,a5
    80005fb8:	00e83023          	sd	a4,0(a6)
  disk.desc[idx[2]].len = 1;
    80005fbc:	6398                	ld	a4,0(a5)
    80005fbe:	9732                	add	a4,a4,a2
    80005fc0:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80005fc2:	4609                	li	a2,2
    80005fc4:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[2]].next = 0;
    80005fc8:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80005fcc:	00ba2223          	sw	a1,4(s4)
  disk.info[idx[0]].b = b;
    80005fd0:	0146b423          	sd	s4,8(a3)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80005fd4:	6794                	ld	a3,8(a5)
    80005fd6:	0026d703          	lhu	a4,2(a3)
    80005fda:	8b1d                	andi	a4,a4,7
    80005fdc:	0706                	slli	a4,a4,0x1
    80005fde:	96ba                	add	a3,a3,a4
    80005fe0:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    80005fe4:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80005fe8:	6798                	ld	a4,8(a5)
    80005fea:	00275783          	lhu	a5,2(a4)
    80005fee:	2785                	addiw	a5,a5,1
    80005ff0:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80005ff4:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80005ff8:	100017b7          	lui	a5,0x10001
    80005ffc:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006000:	004a2783          	lw	a5,4(s4)
    sleep(b, &disk.vdisk_lock);
    80006004:	0001c917          	auipc	s2,0x1c
    80006008:	d4490913          	addi	s2,s2,-700 # 80021d48 <disk+0x128>
  while(b->disk == 1) {
    8000600c:	4485                	li	s1,1
    8000600e:	00b79c63          	bne	a5,a1,80006026 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    80006012:	85ca                	mv	a1,s2
    80006014:	8552                	mv	a0,s4
    80006016:	ffffc097          	auipc	ra,0xffffc
    8000601a:	026080e7          	jalr	38(ra) # 8000203c <sleep>
  while(b->disk == 1) {
    8000601e:	004a2783          	lw	a5,4(s4)
    80006022:	fe9788e3          	beq	a5,s1,80006012 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    80006026:	f9042903          	lw	s2,-112(s0)
    8000602a:	00290713          	addi	a4,s2,2
    8000602e:	0712                	slli	a4,a4,0x4
    80006030:	0001c797          	auipc	a5,0x1c
    80006034:	bf078793          	addi	a5,a5,-1040 # 80021c20 <disk>
    80006038:	97ba                	add	a5,a5,a4
    8000603a:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    8000603e:	0001c997          	auipc	s3,0x1c
    80006042:	be298993          	addi	s3,s3,-1054 # 80021c20 <disk>
    80006046:	00491713          	slli	a4,s2,0x4
    8000604a:	0009b783          	ld	a5,0(s3)
    8000604e:	97ba                	add	a5,a5,a4
    80006050:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006054:	854a                	mv	a0,s2
    80006056:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    8000605a:	00000097          	auipc	ra,0x0
    8000605e:	b9c080e7          	jalr	-1124(ra) # 80005bf6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006062:	8885                	andi	s1,s1,1
    80006064:	f0ed                	bnez	s1,80006046 <virtio_disk_rw+0x1e4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006066:	0001c517          	auipc	a0,0x1c
    8000606a:	ce250513          	addi	a0,a0,-798 # 80021d48 <disk+0x128>
    8000606e:	ffffb097          	auipc	ra,0xffffb
    80006072:	c16080e7          	jalr	-1002(ra) # 80000c84 <release>
}
    80006076:	70a6                	ld	ra,104(sp)
    80006078:	7406                	ld	s0,96(sp)
    8000607a:	64e6                	ld	s1,88(sp)
    8000607c:	6946                	ld	s2,80(sp)
    8000607e:	69a6                	ld	s3,72(sp)
    80006080:	6a06                	ld	s4,64(sp)
    80006082:	7ae2                	ld	s5,56(sp)
    80006084:	7b42                	ld	s6,48(sp)
    80006086:	7ba2                	ld	s7,40(sp)
    80006088:	7c02                	ld	s8,32(sp)
    8000608a:	6ce2                	ld	s9,24(sp)
    8000608c:	6d42                	ld	s10,16(sp)
    8000608e:	6165                	addi	sp,sp,112
    80006090:	8082                	ret

0000000080006092 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006092:	1101                	addi	sp,sp,-32
    80006094:	ec06                	sd	ra,24(sp)
    80006096:	e822                	sd	s0,16(sp)
    80006098:	e426                	sd	s1,8(sp)
    8000609a:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    8000609c:	0001c497          	auipc	s1,0x1c
    800060a0:	b8448493          	addi	s1,s1,-1148 # 80021c20 <disk>
    800060a4:	0001c517          	auipc	a0,0x1c
    800060a8:	ca450513          	addi	a0,a0,-860 # 80021d48 <disk+0x128>
    800060ac:	ffffb097          	auipc	ra,0xffffb
    800060b0:	b24080e7          	jalr	-1244(ra) # 80000bd0 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800060b4:	10001737          	lui	a4,0x10001
    800060b8:	533c                	lw	a5,96(a4)
    800060ba:	8b8d                	andi	a5,a5,3
    800060bc:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800060be:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800060c2:	689c                	ld	a5,16(s1)
    800060c4:	0204d703          	lhu	a4,32(s1)
    800060c8:	0027d783          	lhu	a5,2(a5)
    800060cc:	04f70863          	beq	a4,a5,8000611c <virtio_disk_intr+0x8a>
    __sync_synchronize();
    800060d0:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800060d4:	6898                	ld	a4,16(s1)
    800060d6:	0204d783          	lhu	a5,32(s1)
    800060da:	8b9d                	andi	a5,a5,7
    800060dc:	078e                	slli	a5,a5,0x3
    800060de:	97ba                	add	a5,a5,a4
    800060e0:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800060e2:	00278713          	addi	a4,a5,2
    800060e6:	0712                	slli	a4,a4,0x4
    800060e8:	9726                	add	a4,a4,s1
    800060ea:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    800060ee:	e721                	bnez	a4,80006136 <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800060f0:	0789                	addi	a5,a5,2
    800060f2:	0792                	slli	a5,a5,0x4
    800060f4:	97a6                	add	a5,a5,s1
    800060f6:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    800060f8:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800060fc:	ffffc097          	auipc	ra,0xffffc
    80006100:	fa4080e7          	jalr	-92(ra) # 800020a0 <wakeup>

    disk.used_idx += 1;
    80006104:	0204d783          	lhu	a5,32(s1)
    80006108:	2785                	addiw	a5,a5,1
    8000610a:	17c2                	slli	a5,a5,0x30
    8000610c:	93c1                	srli	a5,a5,0x30
    8000610e:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006112:	6898                	ld	a4,16(s1)
    80006114:	00275703          	lhu	a4,2(a4)
    80006118:	faf71ce3          	bne	a4,a5,800060d0 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    8000611c:	0001c517          	auipc	a0,0x1c
    80006120:	c2c50513          	addi	a0,a0,-980 # 80021d48 <disk+0x128>
    80006124:	ffffb097          	auipc	ra,0xffffb
    80006128:	b60080e7          	jalr	-1184(ra) # 80000c84 <release>
}
    8000612c:	60e2                	ld	ra,24(sp)
    8000612e:	6442                	ld	s0,16(sp)
    80006130:	64a2                	ld	s1,8(sp)
    80006132:	6105                	addi	sp,sp,32
    80006134:	8082                	ret
      panic("virtio_disk_intr status");
    80006136:	00002517          	auipc	a0,0x2
    8000613a:	71250513          	addi	a0,a0,1810 # 80008848 <syscalls+0x3d8>
    8000613e:	ffffa097          	auipc	ra,0xffffa
    80006142:	3fc080e7          	jalr	1020(ra) # 8000053a <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051073          	csrw	sscratch,a0
    80007004:	02000537          	lui	a0,0x2000
    80007008:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    8000700a:	0536                	slli	a0,a0,0xd
    8000700c:	02153423          	sd	ra,40(a0)
    80007010:	02253823          	sd	sp,48(a0)
    80007014:	02353c23          	sd	gp,56(a0)
    80007018:	04453023          	sd	tp,64(a0)
    8000701c:	04553423          	sd	t0,72(a0)
    80007020:	04653823          	sd	t1,80(a0)
    80007024:	04753c23          	sd	t2,88(a0)
    80007028:	f120                	sd	s0,96(a0)
    8000702a:	f524                	sd	s1,104(a0)
    8000702c:	fd2c                	sd	a1,120(a0)
    8000702e:	e150                	sd	a2,128(a0)
    80007030:	e554                	sd	a3,136(a0)
    80007032:	e958                	sd	a4,144(a0)
    80007034:	ed5c                	sd	a5,152(a0)
    80007036:	0b053023          	sd	a6,160(a0)
    8000703a:	0b153423          	sd	a7,168(a0)
    8000703e:	0b253823          	sd	s2,176(a0)
    80007042:	0b353c23          	sd	s3,184(a0)
    80007046:	0d453023          	sd	s4,192(a0)
    8000704a:	0d553423          	sd	s5,200(a0)
    8000704e:	0d653823          	sd	s6,208(a0)
    80007052:	0d753c23          	sd	s7,216(a0)
    80007056:	0f853023          	sd	s8,224(a0)
    8000705a:	0f953423          	sd	s9,232(a0)
    8000705e:	0fa53823          	sd	s10,240(a0)
    80007062:	0fb53c23          	sd	s11,248(a0)
    80007066:	11c53023          	sd	t3,256(a0)
    8000706a:	11d53423          	sd	t4,264(a0)
    8000706e:	11e53823          	sd	t5,272(a0)
    80007072:	11f53c23          	sd	t6,280(a0)
    80007076:	140022f3          	csrr	t0,sscratch
    8000707a:	06553823          	sd	t0,112(a0)
    8000707e:	00853103          	ld	sp,8(a0)
    80007082:	02053203          	ld	tp,32(a0)
    80007086:	01053283          	ld	t0,16(a0)
    8000708a:	00053303          	ld	t1,0(a0)
    8000708e:	12000073          	sfence.vma
    80007092:	18031073          	csrw	satp,t1
    80007096:	12000073          	sfence.vma
    8000709a:	8282                	jr	t0

000000008000709c <userret>:
    8000709c:	12000073          	sfence.vma
    800070a0:	18051073          	csrw	satp,a0
    800070a4:	12000073          	sfence.vma
    800070a8:	02000537          	lui	a0,0x2000
    800070ac:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    800070ae:	0536                	slli	a0,a0,0xd
    800070b0:	02853083          	ld	ra,40(a0)
    800070b4:	03053103          	ld	sp,48(a0)
    800070b8:	03853183          	ld	gp,56(a0)
    800070bc:	04053203          	ld	tp,64(a0)
    800070c0:	04853283          	ld	t0,72(a0)
    800070c4:	05053303          	ld	t1,80(a0)
    800070c8:	05853383          	ld	t2,88(a0)
    800070cc:	7120                	ld	s0,96(a0)
    800070ce:	7524                	ld	s1,104(a0)
    800070d0:	7d2c                	ld	a1,120(a0)
    800070d2:	6150                	ld	a2,128(a0)
    800070d4:	6554                	ld	a3,136(a0)
    800070d6:	6958                	ld	a4,144(a0)
    800070d8:	6d5c                	ld	a5,152(a0)
    800070da:	0a053803          	ld	a6,160(a0)
    800070de:	0a853883          	ld	a7,168(a0)
    800070e2:	0b053903          	ld	s2,176(a0)
    800070e6:	0b853983          	ld	s3,184(a0)
    800070ea:	0c053a03          	ld	s4,192(a0)
    800070ee:	0c853a83          	ld	s5,200(a0)
    800070f2:	0d053b03          	ld	s6,208(a0)
    800070f6:	0d853b83          	ld	s7,216(a0)
    800070fa:	0e053c03          	ld	s8,224(a0)
    800070fe:	0e853c83          	ld	s9,232(a0)
    80007102:	0f053d03          	ld	s10,240(a0)
    80007106:	0f853d83          	ld	s11,248(a0)
    8000710a:	10053e03          	ld	t3,256(a0)
    8000710e:	10853e83          	ld	t4,264(a0)
    80007112:	11053f03          	ld	t5,272(a0)
    80007116:	11853f83          	ld	t6,280(a0)
    8000711a:	7928                	ld	a0,112(a0)
    8000711c:	10200073          	sret
	...


user/_whoami:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <main>:
#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
#include "user/sid.h"

int main(int argc, char **argv) {
   0:	1141                	addi	sp,sp,-16
   2:	e406                	sd	ra,8(sp)
   4:	e022                	sd	s0,0(sp)
   6:	0800                	addi	s0,sp,16
    printf("Student ID:   %d\n", sid);
   8:	782be5b7          	lui	a1,0x782be
   c:	36c58593          	addi	a1,a1,876 # 782be36c <base+0x782bd35c>
  10:	00000517          	auipc	a0,0x0
  14:	7c050513          	addi	a0,a0,1984 # 7d0 <malloc+0xe8>
  18:	00000097          	auipc	ra,0x0
  1c:	618080e7          	jalr	1560(ra) # 630 <printf>
    printf("Student name: %s\n", sname);
  20:	00000597          	auipc	a1,0x0
  24:	7c858593          	addi	a1,a1,1992 # 7e8 <malloc+0x100>
  28:	00000517          	auipc	a0,0x0
  2c:	7d050513          	addi	a0,a0,2000 # 7f8 <malloc+0x110>
  30:	00000097          	auipc	ra,0x0
  34:	600080e7          	jalr	1536(ra) # 630 <printf>
    exit(0);
  38:	4501                	li	a0,0
  3a:	00000097          	auipc	ra,0x0
  3e:	28e080e7          	jalr	654(ra) # 2c8 <exit>

0000000000000042 <_main>:
//
// wrapper so that it's OK if main() does not call exit().
//
void
_main()
{
  42:	1141                	addi	sp,sp,-16
  44:	e406                	sd	ra,8(sp)
  46:	e022                	sd	s0,0(sp)
  48:	0800                	addi	s0,sp,16
  extern int main();
  main();
  4a:	00000097          	auipc	ra,0x0
  4e:	fb6080e7          	jalr	-74(ra) # 0 <main>
  exit(0);
  52:	4501                	li	a0,0
  54:	00000097          	auipc	ra,0x0
  58:	274080e7          	jalr	628(ra) # 2c8 <exit>

000000000000005c <strcpy>:
}

char*
strcpy(char *s, const char *t)
{
  5c:	1141                	addi	sp,sp,-16
  5e:	e422                	sd	s0,8(sp)
  60:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
  62:	87aa                	mv	a5,a0
  64:	0585                	addi	a1,a1,1
  66:	0785                	addi	a5,a5,1
  68:	fff5c703          	lbu	a4,-1(a1)
  6c:	fee78fa3          	sb	a4,-1(a5)
  70:	fb75                	bnez	a4,64 <strcpy+0x8>
    ;
  return os;
}
  72:	6422                	ld	s0,8(sp)
  74:	0141                	addi	sp,sp,16
  76:	8082                	ret

0000000000000078 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  78:	1141                	addi	sp,sp,-16
  7a:	e422                	sd	s0,8(sp)
  7c:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
  7e:	00054783          	lbu	a5,0(a0)
  82:	cb91                	beqz	a5,96 <strcmp+0x1e>
  84:	0005c703          	lbu	a4,0(a1)
  88:	00f71763          	bne	a4,a5,96 <strcmp+0x1e>
    p++, q++;
  8c:	0505                	addi	a0,a0,1
  8e:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
  90:	00054783          	lbu	a5,0(a0)
  94:	fbe5                	bnez	a5,84 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
  96:	0005c503          	lbu	a0,0(a1)
}
  9a:	40a7853b          	subw	a0,a5,a0
  9e:	6422                	ld	s0,8(sp)
  a0:	0141                	addi	sp,sp,16
  a2:	8082                	ret

00000000000000a4 <strlen>:

uint
strlen(const char *s)
{
  a4:	1141                	addi	sp,sp,-16
  a6:	e422                	sd	s0,8(sp)
  a8:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
  aa:	00054783          	lbu	a5,0(a0)
  ae:	cf91                	beqz	a5,ca <strlen+0x26>
  b0:	0505                	addi	a0,a0,1
  b2:	87aa                	mv	a5,a0
  b4:	86be                	mv	a3,a5
  b6:	0785                	addi	a5,a5,1
  b8:	fff7c703          	lbu	a4,-1(a5)
  bc:	ff65                	bnez	a4,b4 <strlen+0x10>
  be:	40a6853b          	subw	a0,a3,a0
  c2:	2505                	addiw	a0,a0,1
    ;
  return n;
}
  c4:	6422                	ld	s0,8(sp)
  c6:	0141                	addi	sp,sp,16
  c8:	8082                	ret
  for(n = 0; s[n]; n++)
  ca:	4501                	li	a0,0
  cc:	bfe5                	j	c4 <strlen+0x20>

00000000000000ce <memset>:

void*
memset(void *dst, int c, uint n)
{
  ce:	1141                	addi	sp,sp,-16
  d0:	e422                	sd	s0,8(sp)
  d2:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
  d4:	ca19                	beqz	a2,ea <memset+0x1c>
  d6:	87aa                	mv	a5,a0
  d8:	1602                	slli	a2,a2,0x20
  da:	9201                	srli	a2,a2,0x20
  dc:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
  e0:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
  e4:	0785                	addi	a5,a5,1
  e6:	fee79de3          	bne	a5,a4,e0 <memset+0x12>
  }
  return dst;
}
  ea:	6422                	ld	s0,8(sp)
  ec:	0141                	addi	sp,sp,16
  ee:	8082                	ret

00000000000000f0 <strchr>:

char*
strchr(const char *s, char c)
{
  f0:	1141                	addi	sp,sp,-16
  f2:	e422                	sd	s0,8(sp)
  f4:	0800                	addi	s0,sp,16
  for(; *s; s++)
  f6:	00054783          	lbu	a5,0(a0)
  fa:	cb99                	beqz	a5,110 <strchr+0x20>
    if(*s == c)
  fc:	00f58763          	beq	a1,a5,10a <strchr+0x1a>
  for(; *s; s++)
 100:	0505                	addi	a0,a0,1
 102:	00054783          	lbu	a5,0(a0)
 106:	fbfd                	bnez	a5,fc <strchr+0xc>
      return (char*)s;
  return 0;
 108:	4501                	li	a0,0
}
 10a:	6422                	ld	s0,8(sp)
 10c:	0141                	addi	sp,sp,16
 10e:	8082                	ret
  return 0;
 110:	4501                	li	a0,0
 112:	bfe5                	j	10a <strchr+0x1a>

0000000000000114 <gets>:

char*
gets(char *buf, int max)
{
 114:	711d                	addi	sp,sp,-96
 116:	ec86                	sd	ra,88(sp)
 118:	e8a2                	sd	s0,80(sp)
 11a:	e4a6                	sd	s1,72(sp)
 11c:	e0ca                	sd	s2,64(sp)
 11e:	fc4e                	sd	s3,56(sp)
 120:	f852                	sd	s4,48(sp)
 122:	f456                	sd	s5,40(sp)
 124:	f05a                	sd	s6,32(sp)
 126:	ec5e                	sd	s7,24(sp)
 128:	1080                	addi	s0,sp,96
 12a:	8baa                	mv	s7,a0
 12c:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 12e:	892a                	mv	s2,a0
 130:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 132:	4aa9                	li	s5,10
 134:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 136:	89a6                	mv	s3,s1
 138:	2485                	addiw	s1,s1,1
 13a:	0344d863          	bge	s1,s4,16a <gets+0x56>
    cc = read(0, &c, 1);
 13e:	4605                	li	a2,1
 140:	faf40593          	addi	a1,s0,-81
 144:	4501                	li	a0,0
 146:	00000097          	auipc	ra,0x0
 14a:	19a080e7          	jalr	410(ra) # 2e0 <read>
    if(cc < 1)
 14e:	00a05e63          	blez	a0,16a <gets+0x56>
    buf[i++] = c;
 152:	faf44783          	lbu	a5,-81(s0)
 156:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 15a:	01578763          	beq	a5,s5,168 <gets+0x54>
 15e:	0905                	addi	s2,s2,1
 160:	fd679be3          	bne	a5,s6,136 <gets+0x22>
  for(i=0; i+1 < max; ){
 164:	89a6                	mv	s3,s1
 166:	a011                	j	16a <gets+0x56>
 168:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 16a:	99de                	add	s3,s3,s7
 16c:	00098023          	sb	zero,0(s3)
  return buf;
}
 170:	855e                	mv	a0,s7
 172:	60e6                	ld	ra,88(sp)
 174:	6446                	ld	s0,80(sp)
 176:	64a6                	ld	s1,72(sp)
 178:	6906                	ld	s2,64(sp)
 17a:	79e2                	ld	s3,56(sp)
 17c:	7a42                	ld	s4,48(sp)
 17e:	7aa2                	ld	s5,40(sp)
 180:	7b02                	ld	s6,32(sp)
 182:	6be2                	ld	s7,24(sp)
 184:	6125                	addi	sp,sp,96
 186:	8082                	ret

0000000000000188 <stat>:

int
stat(const char *n, struct stat *st)
{
 188:	1101                	addi	sp,sp,-32
 18a:	ec06                	sd	ra,24(sp)
 18c:	e822                	sd	s0,16(sp)
 18e:	e426                	sd	s1,8(sp)
 190:	e04a                	sd	s2,0(sp)
 192:	1000                	addi	s0,sp,32
 194:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 196:	4581                	li	a1,0
 198:	00000097          	auipc	ra,0x0
 19c:	170080e7          	jalr	368(ra) # 308 <open>
  if(fd < 0)
 1a0:	02054563          	bltz	a0,1ca <stat+0x42>
 1a4:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 1a6:	85ca                	mv	a1,s2
 1a8:	00000097          	auipc	ra,0x0
 1ac:	178080e7          	jalr	376(ra) # 320 <fstat>
 1b0:	892a                	mv	s2,a0
  close(fd);
 1b2:	8526                	mv	a0,s1
 1b4:	00000097          	auipc	ra,0x0
 1b8:	13c080e7          	jalr	316(ra) # 2f0 <close>
  return r;
}
 1bc:	854a                	mv	a0,s2
 1be:	60e2                	ld	ra,24(sp)
 1c0:	6442                	ld	s0,16(sp)
 1c2:	64a2                	ld	s1,8(sp)
 1c4:	6902                	ld	s2,0(sp)
 1c6:	6105                	addi	sp,sp,32
 1c8:	8082                	ret
    return -1;
 1ca:	597d                	li	s2,-1
 1cc:	bfc5                	j	1bc <stat+0x34>

00000000000001ce <atoi>:

int
atoi(const char *s)
{
 1ce:	1141                	addi	sp,sp,-16
 1d0:	e422                	sd	s0,8(sp)
 1d2:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 1d4:	00054683          	lbu	a3,0(a0)
 1d8:	fd06879b          	addiw	a5,a3,-48
 1dc:	0ff7f793          	zext.b	a5,a5
 1e0:	4625                	li	a2,9
 1e2:	02f66863          	bltu	a2,a5,212 <atoi+0x44>
 1e6:	872a                	mv	a4,a0
  n = 0;
 1e8:	4501                	li	a0,0
    n = n*10 + *s++ - '0';
 1ea:	0705                	addi	a4,a4,1
 1ec:	0025179b          	slliw	a5,a0,0x2
 1f0:	9fa9                	addw	a5,a5,a0
 1f2:	0017979b          	slliw	a5,a5,0x1
 1f6:	9fb5                	addw	a5,a5,a3
 1f8:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 1fc:	00074683          	lbu	a3,0(a4)
 200:	fd06879b          	addiw	a5,a3,-48
 204:	0ff7f793          	zext.b	a5,a5
 208:	fef671e3          	bgeu	a2,a5,1ea <atoi+0x1c>
  return n;
}
 20c:	6422                	ld	s0,8(sp)
 20e:	0141                	addi	sp,sp,16
 210:	8082                	ret
  n = 0;
 212:	4501                	li	a0,0
 214:	bfe5                	j	20c <atoi+0x3e>

0000000000000216 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 216:	1141                	addi	sp,sp,-16
 218:	e422                	sd	s0,8(sp)
 21a:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 21c:	02b57463          	bgeu	a0,a1,244 <memmove+0x2e>
    while(n-- > 0)
 220:	00c05f63          	blez	a2,23e <memmove+0x28>
 224:	1602                	slli	a2,a2,0x20
 226:	9201                	srli	a2,a2,0x20
 228:	00c507b3          	add	a5,a0,a2
  dst = vdst;
 22c:	872a                	mv	a4,a0
      *dst++ = *src++;
 22e:	0585                	addi	a1,a1,1
 230:	0705                	addi	a4,a4,1
 232:	fff5c683          	lbu	a3,-1(a1)
 236:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 23a:	fee79ae3          	bne	a5,a4,22e <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 23e:	6422                	ld	s0,8(sp)
 240:	0141                	addi	sp,sp,16
 242:	8082                	ret
    dst += n;
 244:	00c50733          	add	a4,a0,a2
    src += n;
 248:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 24a:	fec05ae3          	blez	a2,23e <memmove+0x28>
 24e:	fff6079b          	addiw	a5,a2,-1
 252:	1782                	slli	a5,a5,0x20
 254:	9381                	srli	a5,a5,0x20
 256:	fff7c793          	not	a5,a5
 25a:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 25c:	15fd                	addi	a1,a1,-1
 25e:	177d                	addi	a4,a4,-1
 260:	0005c683          	lbu	a3,0(a1)
 264:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 268:	fee79ae3          	bne	a5,a4,25c <memmove+0x46>
 26c:	bfc9                	j	23e <memmove+0x28>

000000000000026e <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 26e:	1141                	addi	sp,sp,-16
 270:	e422                	sd	s0,8(sp)
 272:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 274:	ca05                	beqz	a2,2a4 <memcmp+0x36>
 276:	fff6069b          	addiw	a3,a2,-1
 27a:	1682                	slli	a3,a3,0x20
 27c:	9281                	srli	a3,a3,0x20
 27e:	0685                	addi	a3,a3,1
 280:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 282:	00054783          	lbu	a5,0(a0)
 286:	0005c703          	lbu	a4,0(a1)
 28a:	00e79863          	bne	a5,a4,29a <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 28e:	0505                	addi	a0,a0,1
    p2++;
 290:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 292:	fed518e3          	bne	a0,a3,282 <memcmp+0x14>
  }
  return 0;
 296:	4501                	li	a0,0
 298:	a019                	j	29e <memcmp+0x30>
      return *p1 - *p2;
 29a:	40e7853b          	subw	a0,a5,a4
}
 29e:	6422                	ld	s0,8(sp)
 2a0:	0141                	addi	sp,sp,16
 2a2:	8082                	ret
  return 0;
 2a4:	4501                	li	a0,0
 2a6:	bfe5                	j	29e <memcmp+0x30>

00000000000002a8 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 2a8:	1141                	addi	sp,sp,-16
 2aa:	e406                	sd	ra,8(sp)
 2ac:	e022                	sd	s0,0(sp)
 2ae:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 2b0:	00000097          	auipc	ra,0x0
 2b4:	f66080e7          	jalr	-154(ra) # 216 <memmove>
}
 2b8:	60a2                	ld	ra,8(sp)
 2ba:	6402                	ld	s0,0(sp)
 2bc:	0141                	addi	sp,sp,16
 2be:	8082                	ret

00000000000002c0 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 2c0:	4885                	li	a7,1
 ecall
 2c2:	00000073          	ecall
 ret
 2c6:	8082                	ret

00000000000002c8 <exit>:
.global exit
exit:
 li a7, SYS_exit
 2c8:	4889                	li	a7,2
 ecall
 2ca:	00000073          	ecall
 ret
 2ce:	8082                	ret

00000000000002d0 <wait>:
.global wait
wait:
 li a7, SYS_wait
 2d0:	488d                	li	a7,3
 ecall
 2d2:	00000073          	ecall
 ret
 2d6:	8082                	ret

00000000000002d8 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 2d8:	4891                	li	a7,4
 ecall
 2da:	00000073          	ecall
 ret
 2de:	8082                	ret

00000000000002e0 <read>:
.global read
read:
 li a7, SYS_read
 2e0:	4895                	li	a7,5
 ecall
 2e2:	00000073          	ecall
 ret
 2e6:	8082                	ret

00000000000002e8 <write>:
.global write
write:
 li a7, SYS_write
 2e8:	48c1                	li	a7,16
 ecall
 2ea:	00000073          	ecall
 ret
 2ee:	8082                	ret

00000000000002f0 <close>:
.global close
close:
 li a7, SYS_close
 2f0:	48d5                	li	a7,21
 ecall
 2f2:	00000073          	ecall
 ret
 2f6:	8082                	ret

00000000000002f8 <kill>:
.global kill
kill:
 li a7, SYS_kill
 2f8:	4899                	li	a7,6
 ecall
 2fa:	00000073          	ecall
 ret
 2fe:	8082                	ret

0000000000000300 <exec>:
.global exec
exec:
 li a7, SYS_exec
 300:	489d                	li	a7,7
 ecall
 302:	00000073          	ecall
 ret
 306:	8082                	ret

0000000000000308 <open>:
.global open
open:
 li a7, SYS_open
 308:	48bd                	li	a7,15
 ecall
 30a:	00000073          	ecall
 ret
 30e:	8082                	ret

0000000000000310 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 310:	48c5                	li	a7,17
 ecall
 312:	00000073          	ecall
 ret
 316:	8082                	ret

0000000000000318 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 318:	48c9                	li	a7,18
 ecall
 31a:	00000073          	ecall
 ret
 31e:	8082                	ret

0000000000000320 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 320:	48a1                	li	a7,8
 ecall
 322:	00000073          	ecall
 ret
 326:	8082                	ret

0000000000000328 <link>:
.global link
link:
 li a7, SYS_link
 328:	48cd                	li	a7,19
 ecall
 32a:	00000073          	ecall
 ret
 32e:	8082                	ret

0000000000000330 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 330:	48d1                	li	a7,20
 ecall
 332:	00000073          	ecall
 ret
 336:	8082                	ret

0000000000000338 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 338:	48a5                	li	a7,9
 ecall
 33a:	00000073          	ecall
 ret
 33e:	8082                	ret

0000000000000340 <dup>:
.global dup
dup:
 li a7, SYS_dup
 340:	48a9                	li	a7,10
 ecall
 342:	00000073          	ecall
 ret
 346:	8082                	ret

0000000000000348 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 348:	48ad                	li	a7,11
 ecall
 34a:	00000073          	ecall
 ret
 34e:	8082                	ret

0000000000000350 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 350:	48b1                	li	a7,12
 ecall
 352:	00000073          	ecall
 ret
 356:	8082                	ret

0000000000000358 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 358:	48b5                	li	a7,13
 ecall
 35a:	00000073          	ecall
 ret
 35e:	8082                	ret

0000000000000360 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 360:	48b9                	li	a7,14
 ecall
 362:	00000073          	ecall
 ret
 366:	8082                	ret

0000000000000368 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 368:	1101                	addi	sp,sp,-32
 36a:	ec06                	sd	ra,24(sp)
 36c:	e822                	sd	s0,16(sp)
 36e:	1000                	addi	s0,sp,32
 370:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 374:	4605                	li	a2,1
 376:	fef40593          	addi	a1,s0,-17
 37a:	00000097          	auipc	ra,0x0
 37e:	f6e080e7          	jalr	-146(ra) # 2e8 <write>
}
 382:	60e2                	ld	ra,24(sp)
 384:	6442                	ld	s0,16(sp)
 386:	6105                	addi	sp,sp,32
 388:	8082                	ret

000000000000038a <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 38a:	7139                	addi	sp,sp,-64
 38c:	fc06                	sd	ra,56(sp)
 38e:	f822                	sd	s0,48(sp)
 390:	f426                	sd	s1,40(sp)
 392:	f04a                	sd	s2,32(sp)
 394:	ec4e                	sd	s3,24(sp)
 396:	0080                	addi	s0,sp,64
 398:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 39a:	c299                	beqz	a3,3a0 <printint+0x16>
 39c:	0805c963          	bltz	a1,42e <printint+0xa4>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 3a0:	2581                	sext.w	a1,a1
  neg = 0;
 3a2:	4881                	li	a7,0
 3a4:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 3a8:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 3aa:	2601                	sext.w	a2,a2
 3ac:	00000517          	auipc	a0,0x0
 3b0:	4c450513          	addi	a0,a0,1220 # 870 <digits>
 3b4:	883a                	mv	a6,a4
 3b6:	2705                	addiw	a4,a4,1
 3b8:	02c5f7bb          	remuw	a5,a1,a2
 3bc:	1782                	slli	a5,a5,0x20
 3be:	9381                	srli	a5,a5,0x20
 3c0:	97aa                	add	a5,a5,a0
 3c2:	0007c783          	lbu	a5,0(a5)
 3c6:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 3ca:	0005879b          	sext.w	a5,a1
 3ce:	02c5d5bb          	divuw	a1,a1,a2
 3d2:	0685                	addi	a3,a3,1
 3d4:	fec7f0e3          	bgeu	a5,a2,3b4 <printint+0x2a>
  if(neg)
 3d8:	00088c63          	beqz	a7,3f0 <printint+0x66>
    buf[i++] = '-';
 3dc:	fd070793          	addi	a5,a4,-48
 3e0:	00878733          	add	a4,a5,s0
 3e4:	02d00793          	li	a5,45
 3e8:	fef70823          	sb	a5,-16(a4)
 3ec:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 3f0:	02e05863          	blez	a4,420 <printint+0x96>
 3f4:	fc040793          	addi	a5,s0,-64
 3f8:	00e78933          	add	s2,a5,a4
 3fc:	fff78993          	addi	s3,a5,-1
 400:	99ba                	add	s3,s3,a4
 402:	377d                	addiw	a4,a4,-1
 404:	1702                	slli	a4,a4,0x20
 406:	9301                	srli	a4,a4,0x20
 408:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 40c:	fff94583          	lbu	a1,-1(s2)
 410:	8526                	mv	a0,s1
 412:	00000097          	auipc	ra,0x0
 416:	f56080e7          	jalr	-170(ra) # 368 <putc>
  while(--i >= 0)
 41a:	197d                	addi	s2,s2,-1
 41c:	ff3918e3          	bne	s2,s3,40c <printint+0x82>
}
 420:	70e2                	ld	ra,56(sp)
 422:	7442                	ld	s0,48(sp)
 424:	74a2                	ld	s1,40(sp)
 426:	7902                	ld	s2,32(sp)
 428:	69e2                	ld	s3,24(sp)
 42a:	6121                	addi	sp,sp,64
 42c:	8082                	ret
    x = -xx;
 42e:	40b005bb          	negw	a1,a1
    neg = 1;
 432:	4885                	li	a7,1
    x = -xx;
 434:	bf85                	j	3a4 <printint+0x1a>

0000000000000436 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 436:	715d                	addi	sp,sp,-80
 438:	e486                	sd	ra,72(sp)
 43a:	e0a2                	sd	s0,64(sp)
 43c:	fc26                	sd	s1,56(sp)
 43e:	f84a                	sd	s2,48(sp)
 440:	f44e                	sd	s3,40(sp)
 442:	f052                	sd	s4,32(sp)
 444:	ec56                	sd	s5,24(sp)
 446:	e85a                	sd	s6,16(sp)
 448:	e45e                	sd	s7,8(sp)
 44a:	e062                	sd	s8,0(sp)
 44c:	0880                	addi	s0,sp,80
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 44e:	0005c903          	lbu	s2,0(a1)
 452:	18090c63          	beqz	s2,5ea <vprintf+0x1b4>
 456:	8aaa                	mv	s5,a0
 458:	8bb2                	mv	s7,a2
 45a:	00158493          	addi	s1,a1,1
  state = 0;
 45e:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 460:	02500a13          	li	s4,37
 464:	4b55                	li	s6,21
 466:	a839                	j	484 <vprintf+0x4e>
        putc(fd, c);
 468:	85ca                	mv	a1,s2
 46a:	8556                	mv	a0,s5
 46c:	00000097          	auipc	ra,0x0
 470:	efc080e7          	jalr	-260(ra) # 368 <putc>
 474:	a019                	j	47a <vprintf+0x44>
    } else if(state == '%'){
 476:	01498d63          	beq	s3,s4,490 <vprintf+0x5a>
  for(i = 0; fmt[i]; i++){
 47a:	0485                	addi	s1,s1,1
 47c:	fff4c903          	lbu	s2,-1(s1)
 480:	16090563          	beqz	s2,5ea <vprintf+0x1b4>
    if(state == 0){
 484:	fe0999e3          	bnez	s3,476 <vprintf+0x40>
      if(c == '%'){
 488:	ff4910e3          	bne	s2,s4,468 <vprintf+0x32>
        state = '%';
 48c:	89d2                	mv	s3,s4
 48e:	b7f5                	j	47a <vprintf+0x44>
      if(c == 'd'){
 490:	13490263          	beq	s2,s4,5b4 <vprintf+0x17e>
 494:	f9d9079b          	addiw	a5,s2,-99
 498:	0ff7f793          	zext.b	a5,a5
 49c:	12fb6563          	bltu	s6,a5,5c6 <vprintf+0x190>
 4a0:	f9d9079b          	addiw	a5,s2,-99
 4a4:	0ff7f713          	zext.b	a4,a5
 4a8:	10eb6f63          	bltu	s6,a4,5c6 <vprintf+0x190>
 4ac:	00271793          	slli	a5,a4,0x2
 4b0:	00000717          	auipc	a4,0x0
 4b4:	36870713          	addi	a4,a4,872 # 818 <malloc+0x130>
 4b8:	97ba                	add	a5,a5,a4
 4ba:	439c                	lw	a5,0(a5)
 4bc:	97ba                	add	a5,a5,a4
 4be:	8782                	jr	a5
        printint(fd, va_arg(ap, int), 10, 1);
 4c0:	008b8913          	addi	s2,s7,8
 4c4:	4685                	li	a3,1
 4c6:	4629                	li	a2,10
 4c8:	000ba583          	lw	a1,0(s7)
 4cc:	8556                	mv	a0,s5
 4ce:	00000097          	auipc	ra,0x0
 4d2:	ebc080e7          	jalr	-324(ra) # 38a <printint>
 4d6:	8bca                	mv	s7,s2
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
        putc(fd, c);
      }
      state = 0;
 4d8:	4981                	li	s3,0
 4da:	b745                	j	47a <vprintf+0x44>
        printint(fd, va_arg(ap, uint64), 10, 0);
 4dc:	008b8913          	addi	s2,s7,8
 4e0:	4681                	li	a3,0
 4e2:	4629                	li	a2,10
 4e4:	000ba583          	lw	a1,0(s7)
 4e8:	8556                	mv	a0,s5
 4ea:	00000097          	auipc	ra,0x0
 4ee:	ea0080e7          	jalr	-352(ra) # 38a <printint>
 4f2:	8bca                	mv	s7,s2
      state = 0;
 4f4:	4981                	li	s3,0
 4f6:	b751                	j	47a <vprintf+0x44>
        printint(fd, va_arg(ap, int), 16, 0);
 4f8:	008b8913          	addi	s2,s7,8
 4fc:	4681                	li	a3,0
 4fe:	4641                	li	a2,16
 500:	000ba583          	lw	a1,0(s7)
 504:	8556                	mv	a0,s5
 506:	00000097          	auipc	ra,0x0
 50a:	e84080e7          	jalr	-380(ra) # 38a <printint>
 50e:	8bca                	mv	s7,s2
      state = 0;
 510:	4981                	li	s3,0
 512:	b7a5                	j	47a <vprintf+0x44>
        printptr(fd, va_arg(ap, uint64));
 514:	008b8c13          	addi	s8,s7,8
 518:	000bb983          	ld	s3,0(s7)
  putc(fd, '0');
 51c:	03000593          	li	a1,48
 520:	8556                	mv	a0,s5
 522:	00000097          	auipc	ra,0x0
 526:	e46080e7          	jalr	-442(ra) # 368 <putc>
  putc(fd, 'x');
 52a:	07800593          	li	a1,120
 52e:	8556                	mv	a0,s5
 530:	00000097          	auipc	ra,0x0
 534:	e38080e7          	jalr	-456(ra) # 368 <putc>
 538:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 53a:	00000b97          	auipc	s7,0x0
 53e:	336b8b93          	addi	s7,s7,822 # 870 <digits>
 542:	03c9d793          	srli	a5,s3,0x3c
 546:	97de                	add	a5,a5,s7
 548:	0007c583          	lbu	a1,0(a5)
 54c:	8556                	mv	a0,s5
 54e:	00000097          	auipc	ra,0x0
 552:	e1a080e7          	jalr	-486(ra) # 368 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 556:	0992                	slli	s3,s3,0x4
 558:	397d                	addiw	s2,s2,-1
 55a:	fe0914e3          	bnez	s2,542 <vprintf+0x10c>
        printptr(fd, va_arg(ap, uint64));
 55e:	8be2                	mv	s7,s8
      state = 0;
 560:	4981                	li	s3,0
 562:	bf21                	j	47a <vprintf+0x44>
        s = va_arg(ap, char*);
 564:	008b8993          	addi	s3,s7,8
 568:	000bb903          	ld	s2,0(s7)
        if(s == 0)
 56c:	02090163          	beqz	s2,58e <vprintf+0x158>
        while(*s != 0){
 570:	00094583          	lbu	a1,0(s2)
 574:	c9a5                	beqz	a1,5e4 <vprintf+0x1ae>
          putc(fd, *s);
 576:	8556                	mv	a0,s5
 578:	00000097          	auipc	ra,0x0
 57c:	df0080e7          	jalr	-528(ra) # 368 <putc>
          s++;
 580:	0905                	addi	s2,s2,1
        while(*s != 0){
 582:	00094583          	lbu	a1,0(s2)
 586:	f9e5                	bnez	a1,576 <vprintf+0x140>
        s = va_arg(ap, char*);
 588:	8bce                	mv	s7,s3
      state = 0;
 58a:	4981                	li	s3,0
 58c:	b5fd                	j	47a <vprintf+0x44>
          s = "(null)";
 58e:	00000917          	auipc	s2,0x0
 592:	28290913          	addi	s2,s2,642 # 810 <malloc+0x128>
        while(*s != 0){
 596:	02800593          	li	a1,40
 59a:	bff1                	j	576 <vprintf+0x140>
        putc(fd, va_arg(ap, uint));
 59c:	008b8913          	addi	s2,s7,8
 5a0:	000bc583          	lbu	a1,0(s7)
 5a4:	8556                	mv	a0,s5
 5a6:	00000097          	auipc	ra,0x0
 5aa:	dc2080e7          	jalr	-574(ra) # 368 <putc>
 5ae:	8bca                	mv	s7,s2
      state = 0;
 5b0:	4981                	li	s3,0
 5b2:	b5e1                	j	47a <vprintf+0x44>
        putc(fd, c);
 5b4:	02500593          	li	a1,37
 5b8:	8556                	mv	a0,s5
 5ba:	00000097          	auipc	ra,0x0
 5be:	dae080e7          	jalr	-594(ra) # 368 <putc>
      state = 0;
 5c2:	4981                	li	s3,0
 5c4:	bd5d                	j	47a <vprintf+0x44>
        putc(fd, '%');
 5c6:	02500593          	li	a1,37
 5ca:	8556                	mv	a0,s5
 5cc:	00000097          	auipc	ra,0x0
 5d0:	d9c080e7          	jalr	-612(ra) # 368 <putc>
        putc(fd, c);
 5d4:	85ca                	mv	a1,s2
 5d6:	8556                	mv	a0,s5
 5d8:	00000097          	auipc	ra,0x0
 5dc:	d90080e7          	jalr	-624(ra) # 368 <putc>
      state = 0;
 5e0:	4981                	li	s3,0
 5e2:	bd61                	j	47a <vprintf+0x44>
        s = va_arg(ap, char*);
 5e4:	8bce                	mv	s7,s3
      state = 0;
 5e6:	4981                	li	s3,0
 5e8:	bd49                	j	47a <vprintf+0x44>
    }
  }
}
 5ea:	60a6                	ld	ra,72(sp)
 5ec:	6406                	ld	s0,64(sp)
 5ee:	74e2                	ld	s1,56(sp)
 5f0:	7942                	ld	s2,48(sp)
 5f2:	79a2                	ld	s3,40(sp)
 5f4:	7a02                	ld	s4,32(sp)
 5f6:	6ae2                	ld	s5,24(sp)
 5f8:	6b42                	ld	s6,16(sp)
 5fa:	6ba2                	ld	s7,8(sp)
 5fc:	6c02                	ld	s8,0(sp)
 5fe:	6161                	addi	sp,sp,80
 600:	8082                	ret

0000000000000602 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 602:	715d                	addi	sp,sp,-80
 604:	ec06                	sd	ra,24(sp)
 606:	e822                	sd	s0,16(sp)
 608:	1000                	addi	s0,sp,32
 60a:	e010                	sd	a2,0(s0)
 60c:	e414                	sd	a3,8(s0)
 60e:	e818                	sd	a4,16(s0)
 610:	ec1c                	sd	a5,24(s0)
 612:	03043023          	sd	a6,32(s0)
 616:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 61a:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 61e:	8622                	mv	a2,s0
 620:	00000097          	auipc	ra,0x0
 624:	e16080e7          	jalr	-490(ra) # 436 <vprintf>
}
 628:	60e2                	ld	ra,24(sp)
 62a:	6442                	ld	s0,16(sp)
 62c:	6161                	addi	sp,sp,80
 62e:	8082                	ret

0000000000000630 <printf>:

void
printf(const char *fmt, ...)
{
 630:	711d                	addi	sp,sp,-96
 632:	ec06                	sd	ra,24(sp)
 634:	e822                	sd	s0,16(sp)
 636:	1000                	addi	s0,sp,32
 638:	e40c                	sd	a1,8(s0)
 63a:	e810                	sd	a2,16(s0)
 63c:	ec14                	sd	a3,24(s0)
 63e:	f018                	sd	a4,32(s0)
 640:	f41c                	sd	a5,40(s0)
 642:	03043823          	sd	a6,48(s0)
 646:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 64a:	00840613          	addi	a2,s0,8
 64e:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 652:	85aa                	mv	a1,a0
 654:	4505                	li	a0,1
 656:	00000097          	auipc	ra,0x0
 65a:	de0080e7          	jalr	-544(ra) # 436 <vprintf>
}
 65e:	60e2                	ld	ra,24(sp)
 660:	6442                	ld	s0,16(sp)
 662:	6125                	addi	sp,sp,96
 664:	8082                	ret

0000000000000666 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 666:	1141                	addi	sp,sp,-16
 668:	e422                	sd	s0,8(sp)
 66a:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 66c:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 670:	00001797          	auipc	a5,0x1
 674:	9907b783          	ld	a5,-1648(a5) # 1000 <freep>
 678:	a02d                	j	6a2 <free+0x3c>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 67a:	4618                	lw	a4,8(a2)
 67c:	9f2d                	addw	a4,a4,a1
 67e:	fee52c23          	sw	a4,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 682:	6398                	ld	a4,0(a5)
 684:	6310                	ld	a2,0(a4)
 686:	a83d                	j	6c4 <free+0x5e>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 688:	ff852703          	lw	a4,-8(a0)
 68c:	9f31                	addw	a4,a4,a2
 68e:	c798                	sw	a4,8(a5)
    p->s.ptr = bp->s.ptr;
 690:	ff053683          	ld	a3,-16(a0)
 694:	a091                	j	6d8 <free+0x72>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 696:	6398                	ld	a4,0(a5)
 698:	00e7e463          	bltu	a5,a4,6a0 <free+0x3a>
 69c:	00e6ea63          	bltu	a3,a4,6b0 <free+0x4a>
{
 6a0:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 6a2:	fed7fae3          	bgeu	a5,a3,696 <free+0x30>
 6a6:	6398                	ld	a4,0(a5)
 6a8:	00e6e463          	bltu	a3,a4,6b0 <free+0x4a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 6ac:	fee7eae3          	bltu	a5,a4,6a0 <free+0x3a>
  if(bp + bp->s.size == p->s.ptr){
 6b0:	ff852583          	lw	a1,-8(a0)
 6b4:	6390                	ld	a2,0(a5)
 6b6:	02059813          	slli	a6,a1,0x20
 6ba:	01c85713          	srli	a4,a6,0x1c
 6be:	9736                	add	a4,a4,a3
 6c0:	fae60de3          	beq	a2,a4,67a <free+0x14>
    bp->s.ptr = p->s.ptr->s.ptr;
 6c4:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 6c8:	4790                	lw	a2,8(a5)
 6ca:	02061593          	slli	a1,a2,0x20
 6ce:	01c5d713          	srli	a4,a1,0x1c
 6d2:	973e                	add	a4,a4,a5
 6d4:	fae68ae3          	beq	a3,a4,688 <free+0x22>
    p->s.ptr = bp->s.ptr;
 6d8:	e394                	sd	a3,0(a5)
  } else
    p->s.ptr = bp;
  freep = p;
 6da:	00001717          	auipc	a4,0x1
 6de:	92f73323          	sd	a5,-1754(a4) # 1000 <freep>
}
 6e2:	6422                	ld	s0,8(sp)
 6e4:	0141                	addi	sp,sp,16
 6e6:	8082                	ret

00000000000006e8 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 6e8:	7139                	addi	sp,sp,-64
 6ea:	fc06                	sd	ra,56(sp)
 6ec:	f822                	sd	s0,48(sp)
 6ee:	f426                	sd	s1,40(sp)
 6f0:	f04a                	sd	s2,32(sp)
 6f2:	ec4e                	sd	s3,24(sp)
 6f4:	e852                	sd	s4,16(sp)
 6f6:	e456                	sd	s5,8(sp)
 6f8:	e05a                	sd	s6,0(sp)
 6fa:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 6fc:	02051493          	slli	s1,a0,0x20
 700:	9081                	srli	s1,s1,0x20
 702:	04bd                	addi	s1,s1,15
 704:	8091                	srli	s1,s1,0x4
 706:	0014899b          	addiw	s3,s1,1
 70a:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 70c:	00001517          	auipc	a0,0x1
 710:	8f453503          	ld	a0,-1804(a0) # 1000 <freep>
 714:	c515                	beqz	a0,740 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 716:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 718:	4798                	lw	a4,8(a5)
 71a:	02977f63          	bgeu	a4,s1,758 <malloc+0x70>
  if(nu < 4096)
 71e:	8a4e                	mv	s4,s3
 720:	0009871b          	sext.w	a4,s3
 724:	6685                	lui	a3,0x1
 726:	00d77363          	bgeu	a4,a3,72c <malloc+0x44>
 72a:	6a05                	lui	s4,0x1
 72c:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 730:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 734:	00001917          	auipc	s2,0x1
 738:	8cc90913          	addi	s2,s2,-1844 # 1000 <freep>
  if(p == (char*)-1)
 73c:	5afd                	li	s5,-1
 73e:	a895                	j	7b2 <malloc+0xca>
    base.s.ptr = freep = prevp = &base;
 740:	00001797          	auipc	a5,0x1
 744:	8d078793          	addi	a5,a5,-1840 # 1010 <base>
 748:	00001717          	auipc	a4,0x1
 74c:	8af73c23          	sd	a5,-1864(a4) # 1000 <freep>
 750:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 752:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 756:	b7e1                	j	71e <malloc+0x36>
      if(p->s.size == nunits)
 758:	02e48c63          	beq	s1,a4,790 <malloc+0xa8>
        p->s.size -= nunits;
 75c:	4137073b          	subw	a4,a4,s3
 760:	c798                	sw	a4,8(a5)
        p += p->s.size;
 762:	02071693          	slli	a3,a4,0x20
 766:	01c6d713          	srli	a4,a3,0x1c
 76a:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 76c:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 770:	00001717          	auipc	a4,0x1
 774:	88a73823          	sd	a0,-1904(a4) # 1000 <freep>
      return (void*)(p + 1);
 778:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 77c:	70e2                	ld	ra,56(sp)
 77e:	7442                	ld	s0,48(sp)
 780:	74a2                	ld	s1,40(sp)
 782:	7902                	ld	s2,32(sp)
 784:	69e2                	ld	s3,24(sp)
 786:	6a42                	ld	s4,16(sp)
 788:	6aa2                	ld	s5,8(sp)
 78a:	6b02                	ld	s6,0(sp)
 78c:	6121                	addi	sp,sp,64
 78e:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 790:	6398                	ld	a4,0(a5)
 792:	e118                	sd	a4,0(a0)
 794:	bff1                	j	770 <malloc+0x88>
  hp->s.size = nu;
 796:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 79a:	0541                	addi	a0,a0,16
 79c:	00000097          	auipc	ra,0x0
 7a0:	eca080e7          	jalr	-310(ra) # 666 <free>
  return freep;
 7a4:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 7a8:	d971                	beqz	a0,77c <malloc+0x94>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 7aa:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 7ac:	4798                	lw	a4,8(a5)
 7ae:	fa9775e3          	bgeu	a4,s1,758 <malloc+0x70>
    if(p == freep)
 7b2:	00093703          	ld	a4,0(s2)
 7b6:	853e                	mv	a0,a5
 7b8:	fef719e3          	bne	a4,a5,7aa <malloc+0xc2>
  p = sbrk(nu * sizeof(Header));
 7bc:	8552                	mv	a0,s4
 7be:	00000097          	auipc	ra,0x0
 7c2:	b92080e7          	jalr	-1134(ra) # 350 <sbrk>
  if(p == (char*)-1)
 7c6:	fd5518e3          	bne	a0,s5,796 <malloc+0xae>
        return 0;
 7ca:	4501                	li	a0,0
 7cc:	bf45                	j	77c <malloc+0x94>

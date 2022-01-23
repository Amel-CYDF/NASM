# NASM x64

### Custom IO
- tested at [boj.kr/10818](boj.kr/10818 "boj.kr/10818") (최소, 최대)

- 몇 가지 관찰들:
 - buffer의 크기는 못해도 1024가 되어야 좋다.
 - 입력 속도는 buffer가 커져도 그닥 빨라지진 않는다.
 - 10^6개 입력 기준,
   - printf : 108ms
   - BUFLEN = 4096 : 68ms
   - BUFLEN = 2^20 : 44ms
   - BUFLEN = 2^22 : 40ms
 - 정도 입니다.

### Heap
- tested at [boj.kr/1927](boj.kr/1927 "boj.kr/1927") (최소 힙)

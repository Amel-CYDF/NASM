# NASM x64 (백준에 내기 위한 Assembly(64bit) 정리)

### Custom IO
- tested at [최소, 최대](boj.kr/10818 "boj.kr/10818") 외 다수

- 몇 가지 관찰들:
  - buffer의 크기는 못해도 1024가 되어야 좋다.
  - 입력 속도는 buffer가 커져도 그닥 빨라지진 않는다.
  - 10^6개 입력 기준,
    - printf : 108ms
    - BUFLEN = 4096 : 68ms
    - BUFLEN = 2^20 : 44ms
    - BUFLEN = 2^22 : 40ms
  - 정도 입니다.

- Macro는 call하기가 귀찮은데 함수형과 속도가 비슷하여 함수형만 쓰고 있음
  - 따라서 Macro 버전 파일에는 잘못된 점이 있을 수 있고, 수정 안하고 있음

### Heap
- tested at [최소 힙](boj.kr/1927 "boj.kr/1927")

### Quick Sort
- tested at [수 정렬하기 2](boj.kr/2751 "boj.kr/2751")

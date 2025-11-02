# DRIVER CONTRACT (언어 무관)


출력: 산출물 + KLC JSONL
종료코드: 0=OK, 10=Compile, 11=Test, 12=Package, 13=Deploy, 1=Other

언어 가이드(요약): Java(Maven/Gradle+JUnit), Node(npm/pnpm+ESLint/Jest), Python(uv/pytest/ruff),
C++(CMake+CTest+clang-tidy). 내부 구현 자유, **KLC 출력만 표준 준수**.

FROM eclipse-temurin:21-jdk AS builder
WORKDIR /app

# gradle wrapper + build scripts 먼저 복사
COPY gradlew ./
COPY gradle gradle
COPY build.gradle settings.gradle ./

# Gradle 캐시 디렉토리 설정
ENV GRADLE_USER_HOME=/cache

# 종속성만 먼저 다운로드
RUN ./gradlew dependencies --no-daemon || return 0

# 나머지 소스 복사
COPY . .

# jar 빌드
RUN ./gradlew clean bootJar -x test --no-daemon

FROM eclipse-temurin:21-jre
WORKDIR /app
COPY --from=builder /app/build/libs/*.jar app.jar
ENTRYPOINT ["java","-jar","app.jar"]

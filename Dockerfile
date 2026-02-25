# 1단계: 빌드
FROM eclipse-temurin:21-jdk AS builder
WORKDIR /app
COPY . .
# Gradle 프로젝트라면
RUN ./gradlew clean bootJar -x test

# 2단계: 실행
FROM eclipse-temurin:21-jre
WORKDIR /app
COPY --from=builder /app/build/libs/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java","-jar","app.jar"]

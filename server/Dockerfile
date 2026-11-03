# syntax=docker/dockerfile:1
FROM maven:3.9.16-amazoncorretto-25 AS build
WORKDIR /workspace
COPY pom.xml .
RUN mvn -B -q dependency:go-offline
COPY src ./src
RUN mvn -B -q -DskipTests package

FROM eclipse-temurin:25.0.5_8-jre-noble
RUN useradd --system --create-home --uid 10001 truereport
WORKDIR /app
COPY --from=build /workspace/target/truereport-server-0.2.0-SNAPSHOT.jar /app/truereport-server.jar
RUN mkdir -p /app/.truereport-storage && chown -R truereport:truereport /app
USER truereport
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "/app/truereport-server.jar"]

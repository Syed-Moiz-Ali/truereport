# syntax=docker/dockerfile:1
FROM maven:3.9.16-amazoncorretto-25 AS build
WORKDIR /workspace
COPY pom.xml .
RUN mvn -B -q dependency:go-offline
COPY src ./src
RUN mvn -B -q -DskipTests package

FROM mcr.microsoft.com/playwright/java:v1.64.0-noble AS chromium

FROM eclipse-temurin:25.0.5_8-jre-noble
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl fonts-liberation libasound2t64 libatk-bridge2.0-0 libatk1.0-0 \
    libatspi2.0-0 libcairo2 libcups2 libdbus-1-3 libexpat1 libgbm1 libglib2.0-0 \
    libgtk-3-0 libnspr4 libnss3 libpango-1.0-0 libudev1 libvulkan1 libx11-6 \
    libxcb1 libxcomposite1 libxdamage1 libxext6 libxfixes3 libxkbcommon0 \
    libxrandr2 xdg-utils \
    && rm -rf /var/lib/apt/lists/*
COPY --from=chromium /ms-playwright/chromium-1248 /opt/chromium
RUN useradd --system --create-home --uid 10001 truereport
WORKDIR /app
COPY --from=build /workspace/target/truereport-server-0.2.0-SNAPSHOT.jar /app/truereport-server.jar
RUN mkdir -p /app/.truereport-storage && chown -R truereport:truereport /app
ENV CHROME_PATH=/opt/chromium/chrome-linux64/chrome
USER truereport
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "/app/truereport-server.jar"]

# ---------- Étape 1 : compilation ----------
FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /build
COPY pom.xml .
RUN mvn -B -q dependency:go-offline
COPY src ./src
RUN mvn -B -q clean package -DskipTests

# ---------- Étape 2 : exécution ----------
FROM eclipse-temurin:21-jre-alpine

# Utilisateur non-root avec UID/GID numériques (requis par Kubernetes runAsNonRoot)
RUN addgroup -S -g 10001 spring && adduser -S -u 10001 -G spring spring

WORKDIR /app
COPY --from=build --chown=10001:10001 /build/target/*.jar app.jar

USER 10001:10001
EXPOSE 8080

ENV JAVA_OPTS="-XX:MaxRAMPercentage=70 -XX:+ExitOnOutOfMemoryError"

HEALTHCHECK --interval=30s --timeout=3s --start-period=60s --retries=3 \
  CMD wget -qO- http://localhost:8080/actuator/health || exit 1

ENTRYPOINT ["sh", "-c", "exec java $JAVA_OPTS -jar app.jar"]
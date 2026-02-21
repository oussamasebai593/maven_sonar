FROM eclipse-temurin:8-jre-alpine

WORKDIR /app

COPY target/devops-app-1.0-SNAPSHOT.jar app.jar

EXPOSE 8080


ENTRYPOINT ["java","-jar","app.jar"]

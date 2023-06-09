# Use a base image with Maven and Java
FROM maven:3.8.3-openjdk-11-slim AS build

# Set the working directory
WORKDIR /build

# Install Git
RUN apt-get update && apt-get install -y git

# Clone the Git repository
RUN git clone https://github.com/mdevopsadmin/Bookstore_1.git .

# Switch to a specific branch, tag, or commit if needed
# RUN git checkout main

# Build the Maven project
RUN mvn clean package

# Analyze the project with SonarQube
RUN mvn sonar:sonar \
    -Dsonar.host.url=http://10.0.216.133:9003 \
    -Dsonar.projectKey=DockerBuild \
    -Dsonar.login=97df365415abb7c63a5038a2cbe49bd00ed0335d

# Use a base image with Tomcat
FROM tomcat:latest

# Set the working directory
WORKDIR /usr/local/tomcat/webapps

# Remove default Tomcat application
RUN rm -rf /usr/local/tomcat/webapps/*

# Copy the built WAR file from the previous stage to the Tomcat webapps directory
COPY --from=build /build/target/your-project.war .

# Expose the default Tomcat port
EXPOSE 8085

# Start Tomcat when the container launches
CMD ["catalina.sh", "run"

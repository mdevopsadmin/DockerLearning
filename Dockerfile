# Use a smaller base image for Maven
FROM mcr.microsoft.com/windows/nanoserver:1809 AS maven

# Set the working directory
WORKDIR /build

# Install Git
RUN powershell -Command "Invoke-WebRequest -Uri https://github.com/git-for-windows/git/releases/download/v2.32.0.windows.2/MinGit-2.32.0.2-64-bit.zip -OutFile MinGit.zip" && \
    powershell -Command "Expand-Archive -Path MinGit.zip -DestinationPath .\" && \
    powershell -Command "Get-ChildItem -Path C:\build -Filter 'cmd' -Recurse -Force | Move-Item -Destination C:\build" && \
    powershell -Command "Remove-Item -Path MinGit.zip"

# Set Git executable path
ENV PATH="${PATH};C:\build\cmd;C:\build\mingw64\bin"

# Install Maven
RUN powershell -Command "Invoke-WebRequest -Uri https://archive.apache.org/dist/maven/maven-3/3.8.4/binaries/apache-maven-3.8.4-bin.zip -OutFile maven.zip" && \
    powershell -Command "Expand-Archive -Path maven.zip -DestinationPath .\" && \
    powershell -Command "Get-ChildItem -Path C:\build -Filter 'apache-maven*' -Recurse -Force | Move-Item -Destination C:\build\maven" && \
    powershell -Command "Remove-Item -Path maven.zip"

# Set Maven executable path
ENV PATH="${PATH};C:\build\maven\bin"

# Clone the Git repository
RUN git clone https://github.com/mdevopsadmin/Bookstore_1.git .

# Switch to a specific branch, tag, or commit if needed
# RUN git checkout master

# Build the Maven project
RUN mvn package

# Use a smaller base image for OpenJDK
FROM mcr.microsoft.com/windows/nanoserver:1809 AS openjdk

# Set the working directory
WORKDIR /java-app

# Copy the built artifacts from the previous stage
COPY --from=maven /build/target/eLibrary.war .

# Set SaonrQube host URL as an environment variable
ENV SONAR_HOST_URL="http://10.0.216.133:9003"

# Analyze the project with SonarQube
RUN mvn sonar:sonar -Dsonar.projectKey="DockerBuild" -Dsonar.login="97df365415abb7c63a5038a2cbe49bd00ed0335d"

# Use a smaller base image for Tomcat
FROM mcr.microsoft.com/windows/nanoserver:1809 AS tomcat

# Set the working directory
WORKDIR /tomcat/webapps

# Remove default Tomcat application
RUN powershell -Command "Remove-Item -Recurse C:\tomcat\webapps\*"

# Copy the WAR file from the previous stage to the Tomcat webapps directory
COPY --from=openjdk /java-app/your-project.war .

# Expose the default Tomcat port
EXPOSE 8085

# Start Tomcat when the container launches
CMD ["cmd.exe", "/c", "catalina.bat", "run"]

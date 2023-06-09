# Use a base image with Maven and OpenJDK for Windows
FROM mcr.microsoft.com/windows/servercore:ltsc2019 AS build

# Set the working directory
WORKDIR C:\build

# Install Git
RUN powershell -Command "Invoke-WebRequest -Uri https://github.com/git-for-windows/git/releases/download/v2.32.0.windows.2/MinGit-2.32.0.2-64-bit.zip -OutFile MinGit.zip" && \
    powershell -Command "Expand-Archive -Path MinGit.zip -DestinationPath .\" && \
    powershell -Command "Get-ChildItem -Path C:\build -Filter 'cmd' -Recurse -Force | Move-Item -Destination C:\build" && \
    powershell -Command "Remove-Item -Path MinGit.zip"

# Set Git executable path
ENV PATH="${PATH};C:\build\cmd;C:\build\mingw64\bin"

# Clone the Git repository
RUN git clone https://github.com/mdevopsadmin/Bookstore_1.git .

# Switch to a specific branch, tag, or commit if needed
# RUN git checkout <branch_or_tag_or_commit>

# Install Maven
RUN powershell -Command "Invoke-WebRequest -Uri https://archive.apache.org/dist/maven/maven-3/3.8.3/binaries/apache-maven-3.8.3-bin.zip -OutFile maven.zip" && \
    powershell -Command "Expand-Archive -Path maven.zip -DestinationPath .\" && \
    powershell -Command "Get-ChildItem -Path C:\build -Filter 'apache-maven*' -Recurse -Force | Move-Item -Destination C:\build\maven" && \
    powershell -Command "Remove-Item -Path maven.zip"

# Set Maven executable path
ENV PATH="${PATH};C:\build\maven\bin"

# Build the Maven project
RUN mvn package

# Analyze the project with SonarQube
RUN mvn sonar:sonar ^
    -Dsonar.host.url=10.0.216.133:9003 ^
    -Dsonar.projectKey=DockerBuild ^
    -Dsonar.login=97df365415abb7c63a5038a2cbe49bd00ed0335d

# Use a base image with Tomcat for Windows
FROM mcr.microsoft.com/windows/nanoserver:ltsc2019 AS final

# Set the working directory
WORKDIR C:\tomcat\webapps

# Remove default Tomcat application
RUN powershell -Command "Remove-Item -Recurse C:\tomcat\webapps\*"

# Copy the built WAR file from the previous stage to the Tomcat webapps directory
COPY --from=build C:\build\target\your-project.war .

# Expose the default Tomcat port
EXPOSE 8085

# Start Tomcat when the container launches
CMD ["cmd.exe", "/c", "catalina.bat", "run"]

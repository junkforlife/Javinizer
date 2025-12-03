FROM python:bullseye

# Add docker entrypoint script
ADD docker-entrypoint.sh /
RUN chmod +x /docker-entrypoint.sh

# Install dependencies
RUN apt-get update \
    && apt-get install -y unzip wget

# Create directories
RUN mkdir -p /home/data/Repository/.universal \
    && mkdir -p /home/Universal

# Add dashboard files
ADD src/Javinizer/Universal/Repository/javinizergui.ps1 /home/data/Repository
ADD src/Javinizer/Universal/Repository/dashboards.ps1 /home/data/Repository/.universal

# Download powershell universal
WORKDIR /home
RUN wget https://imsreleases.blob.core.windows.net/universal/production/1.5.13/Universal.linux-x64.1.5.13.zip

# Extract powershell universal to /home/Universal
RUN unzip -q /home/Universal.linux-x64.1.5.13.zip -d /home/Universal/ \
    && chmod +x /home/Universal/Universal.Server \
    && rm /home/Universal.linux-x64.1.5.13.zip

# Install mediainfo
RUN apt-get install -y mediainfo

RUN wget https://packages.microsoft.com/config/debian/11/packages-microsoft-prod.deb \
    && dpkg -i packages-microsoft-prod.deb \
    && apt-get update && apt install -y dotnet-sdk-8.0

# Install pwsh
#RUN wget "http://ftp.us.debian.org/debian/pool/main/i/icu/libicu72_72.1-3+deb12u1_amd64.deb" && dpkg -i libicu72_72.1-3+deb12u1_amd64.deb
RUN wget https://github.com/PowerShell/PowerShell/releases/download/v7.3.11/powershell_7.3.11-1.deb_amd64.deb \
    && dpkg -i powershell_7.3.11-1.deb_amd64.deb \
    && apt-get install -f
#RUN wget https://packages.microsoft.com/config/debian/11/packages-microsoft-prod.deb \
#    && dpkg -i packages-microsoft-prod.deb \
#    && apt-get update \
#    && apt-get install -y powershell \
#    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /home/data/Repository/repo/Javinizer
ADD src/Javinizer /home/data/Repository/repo/Javinizer
RUN pwsh -c "Register-PSRepository -Name 'home' -SourceLocation '/home/data/Repository/repo' -InstallationPolicy Trusted" \
     && pwsh -c "Publish-Module -Path /home/data/Repository/repo/Javinizer -Repository home -NuGetApiKey 'ABC123'" && pwsh -c "Install-Module Javinizer -Repository 'home'"

# Install pwsh modules
RUN pwsh -c "Set-PSRepository 'PSGallery' -InstallationPolicy Trusted" \
    && pwsh -c "Install-Module UniversalDashboard.Style" \
    && pwsh -c "Install-Module UniversalDashboard.Charts" \
    && pwsh -c "Install-Module UniversalDashboard.UDPlayer" \
    && pwsh -c "Install-Module UniversalDashboard.UDSpinner" \
    && pwsh -c "Install-Module UniversalDashboard.UDScrollUp" \
    && pwsh -c "Install-Module UniversalDashboard.CodeEditor"

# Install python modules
RUN pip3 install pillow \
    google_trans_new \
    googletrans==4.0.0rc1 \
    requests

# Clean up
#RUN apt-get purge unzip \
#    wget \
#    && apt-get autoremove

# Create symlink to module settings file
RUN pwsh -c "ln -s (Join-Path (Get-InstalledModule Javinizer).InstalledLocation -ChildPath jvSettings.json) /home/jvSettings.json"

# Add powershell universal environmental variables
ENV Kestrel__Endpoints__HTTP__Url http://*:8600
ENV Data__RepositoryPath ./data/Repository
ENV Data__ConnectionString ./data/database.db
ENV UniversalDashboard__AssetsFolder ./data/UniversalDashboard
ENV Logging__Path ./data/logs/log.txt

EXPOSE 8600
ENTRYPOINT ["/docker-entrypoint.sh"]

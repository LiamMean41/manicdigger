#!/bin/bash
# ManicDigger Development Helper Script for Linux
# Handles NuGet package restoration without requiring apt-get install

set -e  # Exit on error

echo "======================================"
echo "ManicDigger Development Helper"
echo "======================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check for build tools
echo "Checking for required tools..."

if ! command_exists mono; then
    echo -e "${RED}✗${NC} Mono runtime not found"
    echo "Install with: sudo apt-get install mono-complete"
    exit 1
fi
echo -e "${GREEN}✓${NC} Found mono"

if command_exists msbuild; then
    BUILD_CMD="msbuild"
    echo -e "${GREEN}✓${NC} Found msbuild"
elif command_exists xbuild; then
    BUILD_CMD="xbuild"
    echo -e "${GREEN}✓${NC} Found xbuild"
else
    echo -e "${RED}✗${NC} No build tool found (msbuild/xbuild)"
    echo "Install with: sudo apt-get install mono-complete"
    exit 1
fi

# Check for NuGet
NUGET_CMD=""
if [ -f "nuget.exe" ]; then
    NUGET_CMD="mono nuget.exe"
    echo -e "${GREEN}✓${NC} Found nuget.exe"
elif command_exists nuget; then
    NUGET_CMD="nuget"
    echo -e "${GREEN}✓${NC} Found nuget command"
elif command_exists dotnet; then
    NUGET_CMD="dotnet"
    echo -e "${GREEN}✓${NC} Found dotnet (will use for restore)"
else
    echo -e "${YELLOW}!${NC} NuGet not found (will download if needed)"
fi

echo ""

# Function to restore packages
restore_packages() {
    echo -e "${YELLOW}Restoring NuGet Packages...${NC}"
    
    if [ -n "$NUGET_CMD" ]; then
        if [ "$NUGET_CMD" = "dotnet" ]; then
            dotnet restore ManicDigger.sln
        else
            $NUGET_CMD restore ManicDigger.sln
        fi
    else
        # Download NuGet.exe if not present
        if [ ! -f "nuget.exe" ]; then
            echo -e "${BLUE}ℹ${NC} Downloading NuGet.exe..."
            wget -q https://dist.nuget.org/win-x86-commandline/latest/nuget.exe
            chmod +x nuget.exe
        fi
        mono nuget.exe restore ManicDigger.sln
    fi
    
    # Fallback: try msbuild restore
    if [ $? -ne 0 ]; then
        echo -e "${YELLOW}!${NC} NuGet restore failed, trying msbuild restore..."
        $BUILD_CMD /t:restore ManicDigger.sln
    fi
    
    echo -e "${GREEN}✓ Packages restored!${NC}"
}

# Function to set X11 environment for running
setup_x11_env() {
    export XMODIFIERS=""
    export GTK_IM_MODULE="gtk-im-context-simple"
    export QT_IM_MODULE="simple"
    echo -e "${BLUE}ℹ${NC} Applied X11/GTK fixes for Mono compatibility"
}

# Main menu
echo "What would you like to do?"
echo "1) Restore NuGet Packages (do this first!)"
echo "2) Build Client"
echo "3) Build Server"
echo "4) Build Both"
echo "5) Run Client"
echo "6) Run Server"
echo "7) Full Build (Restore + Build Client)"
echo "8) Full Build (Restore + Build Server)"
echo "9) Full Build (Restore + Build Everything)"
echo "10) Build and Run Client"
echo "11) Build and Run Server"
echo "12) Clean build files"
echo "13) Quick fix (ENet library symlink)"
echo "14) Download NuGet.exe manually"
read -p "Enter choice [1-14]: " choice

case $choice in
    1)
        restore_packages
        ;;
    2)
        echo -e "${YELLOW}Building Client...${NC}"
        $BUILD_CMD /p:Configuration=Release ManicDigger.sln /t:ManicDigger
        echo -e "${GREEN}✓ Build complete!${NC}"
        ;;
    3)
        echo -e "${YELLOW}Building Server...${NC}"
        $BUILD_CMD /p:Configuration=Release ManicDigger.sln /t:ManicDiggerServer
        echo -e "${GREEN}✓ Build complete!${NC}"
        ;;
    4)
        echo -e "${YELLOW}Building Everything...${NC}"
        $BUILD_CMD /p:Configuration=Release ManicDigger.sln
        echo -e "${GREEN}✓ Build complete!${NC}"
        ;;
    5)
        echo -e "${YELLOW}Running Client...${NC}"
        if [ ! -f "ManicDigger/bin/Release/ManicDigger.exe" ]; then
            echo -e "${RED}✗ Client not built yet. Build it first (option 2 or 7)${NC}"
            exit 1
        fi
        setup_x11_env
        mono ManicDigger/bin/Release/ManicDigger.exe
        ;;
    6)
        echo -e "${YELLOW}Running Server...${NC}"
        if [ ! -f "ManicDiggerServer/bin/Release/ManicDiggerServer.exe" ]; then
            echo -e "${RED}✗ Server not built yet. Build it first (option 3 or 8)${NC}"
            exit 1
        fi
        setup_x11_env
        mono ManicDiggerServer/bin/Release/ManicDiggerServer.exe
        ;;
    7)
        restore_packages
        echo ""
        echo -e "${YELLOW}Building Client...${NC}"
        $BUILD_CMD /p:Configuration=Release ManicDigger.sln /t:ManicDigger
        echo -e "${GREEN}✓ Build complete!${NC}"
        ;;
    8)
        restore_packages
        echo ""
        echo -e "${YELLOW}Building Server...${NC}"
        $BUILD_CMD /p:Configuration=Release ManicDigger.sln /t:ManicDiggerServer
        echo -e "${GREEN}✓ Build complete!${NC}"
        ;;
    9)
        restore_packages
        echo ""
        echo -e "${YELLOW}Building Everything...${NC}"
        $BUILD_CMD /p:Configuration=Release ManicDigger.sln
        echo -e "${GREEN}✓ Build complete!${NC}"
        ;;
    10)
        echo -e "${YELLOW}Building Client...${NC}"
        $BUILD_CMD /p:Configuration=Release ManicDigger.sln /t:ManicDigger
        echo -e "${GREEN}✓ Build complete!${NC}"
        echo ""
        echo -e "${YELLOW}Running Client...${NC}"
        setup_x11_env
        mono ManicDigger/bin/Release/ManicDigger.exe
        ;;
    11)
        echo -e "${YELLOW}Building Server...${NC}"
        $BUILD_CMD /p:Configuration=Release ManicDigger.sln /t:ManicDiggerServer
        echo -e "${GREEN}✓ Build complete!${NC}"
        echo ""
        echo -e "${YELLOW}Running Server...${NC}"
        setup_x11_env
        mono ManicDiggerServer/bin/Release/ManicDiggerServer.exe
        ;;
    12)
        echo -e "${YELLOW}Cleaning build files...${NC}"
        find . -type d \( -name "bin" -o -name "obj" \) -exec rm -rf {} + 2>/dev/null || true
        rm -rf packages/
        echo -e "${GREEN}✓ Clean complete!${NC}"
        echo -e "${BLUE}ℹ Run option 1 to restore packages and rebuild${NC}"
        ;;
    13)
        echo -e "${YELLOW}Applying ENet library fix...${NC}"
        
        # Check which version of libenet is available
        if [ -f "/usr/lib/x86_64-linux-gnu/libenet.so.2" ]; then
            sudo ln -sf /usr/lib/x86_64-linux-gnu/libenet.so.2 /usr/lib/x86_64-linux-gnu/libenet.so.7
            echo -e "${GREEN}✓ Created symlink for libenet.so.7 -> libenet.so.2${NC}"
        elif [ -f "/usr/lib/x86_64-linux-gnu/libenet.so.1" ]; then
            sudo ln -sf /usr/lib/x86_64-linux-gnu/libenet.so.1 /usr/lib/x86_64-linux-gnu/libenet.so.7
            echo -e "${GREEN}✓ Created symlink for libenet.so.7 -> libenet.so.1${NC}"
        else
            echo -e "${RED}✗ No libenet found. Installing...${NC}"
            sudo apt-get update
            sudo apt-get install -y libenet-dev
            if [ -f "/usr/lib/x86_64-linux-gnu/libenet.so.2" ]; then
                sudo ln -sf /usr/lib/x86_64-linux-gnu/libenet.so.2 /usr/lib/x86_64-linux-gnu/libenet.so.7
                echo -e "${GREEN}✓ Installed and linked libenet${NC}"
            fi
        fi
        ;;
    14)
        echo -e "${YELLOW}Downloading NuGet.exe...${NC}"
        wget https://dist.nuget.org/win-x86-commandline/latest/nuget.exe
        chmod +x nuget.exe
        echo -e "${GREEN}✓ NuGet.exe downloaded!${NC}"
        echo -e "${BLUE}ℹ Now run option 1 to restore packages${NC}"
        ;;
    *)
        echo -e "${RED}Invalid choice${NC}"
        exit 1
        ;;
esac

echo ""
echo "======================================"
echo "Done!"
echo "======================================"
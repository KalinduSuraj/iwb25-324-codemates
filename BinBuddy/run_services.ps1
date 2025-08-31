# BinBuddy Service Runner Scripts

Write-Host "BinBuddy Waste Management System" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Green
Write-Host ""

# Function to check if a port is available
function Test-Port {
    param([int]$Port)
    try {
        $listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Any, $Port)
        $listener.Start()
        $listener.Stop()
        return $true
    }
    catch {
        return $false
    }
}

# Function to run a specific service
function Start-Service {
    param(
        [string]$ServiceName,
        [string]$ServiceFile,
        [int]$Port
    )
    
    Write-Host "Starting $ServiceName on port $Port..." -ForegroundColor Yellow
    
    if (-not (Test-Port -Port $Port)) {
        Write-Host "Warning: Port $Port is already in use!" -ForegroundColor Red
        return
    }
    
    Write-Host "Running: bal run $ServiceFile" -ForegroundColor Cyan
    Start-Process -FilePath "bal" -ArgumentList "run", $ServiceFile -NoNewWindow
    Start-Sleep -Seconds 2
    Write-Host "$ServiceName started successfully!" -ForegroundColor Green
    Write-Host "Health check: http://localhost:$Port/api/$($ServiceName.ToLower())/health" -ForegroundColor Blue
    Write-Host ""
}

# Menu options
Write-Host "Choose an option:" -ForegroundColor Yellow
Write-Host "1. Start Customer Service (Port 8081)"
Write-Host "2. Start Collector Service (Port 8082)" 
Write-Host "3. Start Admin Service (Port 8083)"
Write-Host "4. Start Main Service (Port 8084)"
Write-Host "5. Start All Services"
Write-Host "6. Check Service Status"
Write-Host "7. Stop All Services"
Write-Host "8. Exit"
Write-Host ""

$choice = Read-Host "Enter your choice (1-8)"

switch ($choice) {
    "1" {
        Start-Service -ServiceName "Customer" -ServiceFile "backend/services/customer_service.bal" -Port 8081
    }
    "2" {
        Start-Service -ServiceName "Collector" -ServiceFile "backend/services/collector_service.bal" -Port 8082
    }
    "3" {
        Start-Service -ServiceName "Admin" -ServiceFile "backend/services/admin_service.bal" -Port 8083
    }
    "4" {
        Start-Service -ServiceName "Main" -ServiceFile "main_service.bal" -Port 8084
    }
    "5" {
        Write-Host "Starting all services..." -ForegroundColor Green
        Start-Service -ServiceName "Customer" -ServiceFile "backend/services/customer_service.bal" -Port 8081
        Start-Service -ServiceName "Collector" -ServiceFile "backend/services/collector_service.bal" -Port 8082
        Start-Service -ServiceName "Admin" -ServiceFile "backend/services/admin_service.bal" -Port 8083
        Start-Service -ServiceName "Main" -ServiceFile "main_service.bal" -Port 8084
        
        Write-Host "All services started!" -ForegroundColor Green
        Write-Host "Main API Documentation: http://localhost:8084/docs" -ForegroundColor Blue
    }
    "6" {
        Write-Host "Checking service status..." -ForegroundColor Yellow
        
        $services = @(
            @{Name="Customer"; Port=8081; Url="http://localhost:8081/api/customer/health"},
            @{Name="Collector"; Port=8082; Url="http://localhost:8082/api/collector/health"},
            @{Name="Admin"; Port=8083; Url="http://localhost:8083/api/admin/health"},
            @{Name="Main"; Port=8084; Url="http://localhost:8084/health"}
        )
        
        foreach ($service in $services) {
            if (Test-Port -Port $service.Port) {
                Write-Host "$($service.Name) Service: ❌ Not Running (Port $($service.Port) available)" -ForegroundColor Red
            } else {
                Write-Host "$($service.Name) Service: ✅ Running (Port $($service.Port))" -ForegroundColor Green
                Write-Host "  Health Check: $($service.Url)" -ForegroundColor Blue
            }
        }
    }
    "7" {
        Write-Host "Stopping all services..." -ForegroundColor Yellow
        Get-Process -Name "bal" -ErrorAction SilentlyContinue | Stop-Process -Force
        Write-Host "All services stopped!" -ForegroundColor Green
    }
    "8" {
        Write-Host "Goodbye!" -ForegroundColor Green
        exit
    }
    default {
        Write-Host "Invalid choice. Please run the script again." -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Press any key to continue..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

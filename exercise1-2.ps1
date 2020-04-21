$vms = Get-AzVM -ResourceGroupName Exercise1-RG

$et=Get-Date

$st=$et.AddDays(-3)

$arr =@()

 foreach($vm in $vms)
 {
 #define a string to store related infomation like vm name etc. then add the string to an array
 $s = ""

 $cpu = Get-AzMetric -ResourceId $vm.Id -MetricName "Percentage CPU" -DetailedOutput `
 -TimeGrain 12:00:00  -WarningAction SilentlyContinue

 $diskReadBytes = Get-AzMetric -ResourceId $vm.Id -MetricName "Disk Read Bytes" -DetailedOutput `
 -TimeGrain 00:01:00  -WarningAction SilentlyContinue

 $cpu_total=0.0
 $diskReadBytes=0.0

  foreach($c in $cpu.Data.Average)
 {
  #this is a average value for 12 hours, so total = $c*12 (or should be $c*12*60*60)
  $cpu_total += $c*12
 }

 foreach($d in $diskReadBytes.Data.Total)
 {
 $diskReadBytes += $d 
 }

 # add all the related info to the string
 $s = "VM Name: " + $vm.name + "; CPU: " +$cpu_total +"; Disk Read Bytes : " + $diskReadBytes + ""

  # add the above string to an array
 $arr += $s
 }

 #check the values in the array
 $arr
# See: https://www.thomasmaurer.ch/2016/01/change-hyper-v-vm-switch-of-virtual-machines-using-powershell/

Get-VM "kworker1" | Get-VMNetworkAdapter | Connect-VMNetworkAdapter -SwitchName "NATSwitch"
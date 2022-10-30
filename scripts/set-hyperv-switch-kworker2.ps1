# See: https://www.thomasmaurer.ch/2016/01/change-hyper-v-vm-switch-of-virtual-machines-using-powershell/

Get-VM "kworker2" | Get-VMNetworkAdapter | Connect-VMNetworkAdapter -SwitchName "NATSwitch"
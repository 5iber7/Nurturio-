"""Boot an available iPhone simulator and run the actual Flutter quest flow."""
import json, subprocess
inventory=json.loads(subprocess.check_output(['xcrun','simctl','list','devices','available','-j'],text=True))
devices=[d for group in inventory['devices'].values() for d in group if d.get('isAvailable') and d['name'].startswith('iPhone')]
if not devices: raise RuntimeError('No available iPhone simulator runtime on this runner.')
device=next((d for d in devices if d['state']=='Booted'),devices[0])
if device['state']!='Booted': subprocess.run(['xcrun','simctl','boot',device['udid']],check=True)
subprocess.run(['xcrun','simctl','bootstatus',device['udid'],'-b'],check=True,timeout=180)
subprocess.run(['flutter','test','integration_test/quest_flow_test.dart','-d',device['udid']],cwd='apps/mobile',check=True,timeout=600)

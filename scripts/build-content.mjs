// Authored, reproducible content source. No AI-generated content enters runtime packs.
import { mkdirSync, writeFileSync } from 'node:fs';
const out = 'apps/mobile/assets/content';
mkdirSync(out, { recursive: true });
const sources = [
  ['bees', 'Penn State Extension', 'Beekeeping resources', 'https://extension.psu.edu/beekeeping-resources'],
  ['bee-seasons', 'Penn State Extension', 'Honey bee management throughout the seasons', 'https://extension.psu.edu/honey-bee-management-throughout-the-seasons'],
  ['oil', 'UC Davis', 'Olive oil processing', 'https://ucfoodquality.ucdavis.edu/olive-oil/olive-oil-processing'],
  ['oil-quality', 'International Olive Council', 'Olive oils', 'https://www.internationaloliveoil.org/olive-world/olive-oil/'],
  ['chickens', 'University of Minnesota Extension', 'Raising chickens for eggs', 'https://extension.umn.edu/agriculture/animals-and-livestock/poultry/raising-chickens-for-eggs'],
  ['tomato', 'University of Minnesota Extension', 'Growing tomatoes', 'https://extension.umn.edu/garden-and-home/yard-and-garden/gardening-in-minnesota/growing-tomatoes'],
  ['herbs', 'University of Minnesota Extension', 'Growing herbs', 'https://extension.umn.edu/garden-and-home/yard-and-garden/gardening-in-minnesota/growing-herbs'],
  ['strawberry', 'University of Maryland Extension', 'Growing strawberries', 'https://www.extension.umd.edu/resource/growing-strawberries-home-garden'],
  ['lettuce', 'University of Minnesota Extension', 'Growing lettuce', 'https://extension.umn.edu/garden-and-home/yard-and-garden/gardening-in-minnesota/growing-lettuce-endive-and-radicchio'],
  ['marigold', 'NC State Extension', 'Tagetes', 'https://plants.ces.ncsu.edu/plants/tagetes/'],
  ['garden', 'University of Minnesota Extension', 'Vegetable growing guides', 'https://extension.umn.edu/vegetables']
].map(([id,publisher,title,url]) => ({ id,publisher,title,url,accessedAt:'2026-10-09',reviewStatus:id.startsWith('bee')?'expert-review-required':'editorial-review-required' }));
const worlds = [
  { id:'honey', name:'The Apiary', subject:'Honey', subtitle:'A little flower. A golden discovery.', icon:'bee', color:'#EDAE45', goal:'Care for a colony and follow nectar to the jar.', sourceIds:['bees','bee-seasons'], glossary:[['Nectar','A sweet liquid made by flowers.'],['Frame','A removable support for honeycomb.'],['Capped honey','Honey sealed into cells with wax.']],
    quests:[
      ['Meet the colony','match','Match the bee to her role.','Workers gather nectar. The queen lays eggs. Drones are male bees.','queen|Egg laying;worker|Nectar gathering;drone|Male bee','Who gathers nectar?','Workers|The beekeeper|Only the queen',0,'The colony works together.',0],
      ['A home for bees','build','Place frames inside the hive.','Frames hold comb where bees rear young and store food.','Frame|Hive;Frame|Hive;Frame|Hive','What do frames support?','Honeycomb|Flower roots|Olive paste',0,'Frames are supports, not boxes of instant honey.',0],
      ['Ready for a visit','sort','Choose protective equipment for a supervised hive visit.','Beekeeping needs training and protective equipment.','Veil|Keep;Gloves|Keep;Bare hands|Leave','Who should guide a real hive visit?','An experienced beekeeper|An app alone|No one',0,'Never approach an unfamiliar hive. Bee stings can cause serious reactions.',0],
      ['From flower to hive','sequence','Follow the journey of nectar.','Workers collect nectar and bring it back to the colony.','Flower|1;Forager|2;Hive|3','Where does nectar begin?','Flowers|Glass jars|Soil bags',0,'Weather and available flowers affect nectar gathering.',8],
      ['Ripen and cap','pour','Help the colony fill cells in this simulation.','Bees process nectar and reduce its water content before sealing ripe honey.','Honey cell|Fill','Does nectar become finished honey instantly?','No, processing takes time|Yes|Only in a jar',0,'Ripening depends on the colony and weather; there is no universal fixed wait.',10],
      ['Leave enough stores','sort','Choose only surplus frames for the harvest.','The colony needs food reserves; harvest decisions must protect those stores.','Surplus frame|Harvest;Food reserve|Leave;Brood frame|Leave','Why leave honey in the hive?','Bees need food|It makes jars heavier|It stops flowers growing',0,'A real beekeeper assesses colony condition before harvesting.',0],
      ['Uncap and extract','timing','Turn the extractor gently after the caps are removed.','An extractor spins prepared frames so honey leaves the comb.','Extractor|Spin','What comes before extraction?','Remove wax caps|Bottle the oil|Plant seeds',0,'Extraction equipment is operated with suitable training.',0],
      ['Filter, jar, celebrate','pour','Fill clean jars with your simulated honey.','Filtering removes wax particles before honey is packaged.','Honey jar|Fill','What belongs in a honey jar?','Prepared honey|Loose wax pieces|Coop bedding',0,'This simulation is an overview, not a food-production safety certificate.',0]
    ] },
  { id:'olive',name:'Olive Grove',subject:'Olive oil',subtitle:'From the branch to the bottle.',icon:'olive',color:'#7E9C59',goal:'Discover how olives become oil through mechanical processing.',sourceIds:['oil','oil-quality'],glossary:[['Malaxation','Slow mixing of olive paste.'],['Pomace','Solids remaining after oil separation.'],['Centrifuge','A machine that separates materials by spinning.']],
    quests:[
      ['Know your tree','match','Match tree, fruit, and product.','Olive oil begins with fruit grown on olive trees.','Tree|Olive tree;Fruit|Olive;Product|Oil','Which part is processed for oil?','The fruit|The trunk|The roots',0,'Climate and variety shape the harvest season.',0],
      ['Harvest with care','sort','Collect sound olives and set damaged fruit aside.','Fruit quality and timely processing matter.','Sound olive|Keep;Damaged olive|Leave;Sound olive|Keep','Which fruit is the better starting point?','Sound olives|Spoiled olives|Leaves alone',0,'Color alone does not certify quality.',0],
      ['Sort and clean','sort','Remove leaves and stones from the fruit.','Processing lines remove foreign material; washing is used where appropriate.','Olive|Keep;Leaf|Leave;Stone|Leave','What should be removed before crushing?','Stones and leaves|All fruit|The oil bottle',0,'Real facilities adjust cleaning to the fruit and equipment.',0],
      ['Crush into paste','timing','Run the simulated crusher at a steady rhythm.','Crushing opens the fruit cells and creates olive paste.','Crusher|Crush','What does crushing produce?','Olive paste|Bread dough|Finished bottled oil',0,'Industrial machinery requires trained operators.',0],
      ['Slowly mix','timing','Mix the paste in the malaxer.','Slow mixing helps prepare the paste for oil separation.','Malaxer|Mix','What is malaxation?','Slow mixing|Growing a tree|Painting a bottle',0,'Actual mixing settings depend on the fruit and equipment.',8],
      ['Separate the oil','sequence','Follow this modern processing line.','Modern processing commonly uses centrifugal separation.','Paste|1;Decanter|2;Separated oil|3','How does a centrifuge work?','By spinning|By planting|By adding leaves',0,'Traditional presses and modern centrifuges are different methods.',0],
      ['Clarify the oil','sort','Keep oil and remove remaining sediment.','Oil can be clarified by filtration, settling, or related methods.','Oil|Keep;Sediment|Leave;Oil|Keep','What is clarification for?','Removing remaining material|Adding stones|Changing the tree',0,'Oil grading requires defined quality checks, not a game score.',0],
      ['Bottle and protect','build','Place a cap and a label on the bottle.','Packaging and storage help protect olive oil quality.','Cap|Bottle;Label|Bottle;Bottle|Shelf','What should oil be protected from?','Excess heat and light|Its own label|A closed bottle',0,'Extra-virgin is a quality category, not a particular color.',0]
    ] },
  { id:'chicken',name:'Chicken Coop',subject:'Chicken care',subtitle:'Happy routines, healthy little neighbors.',icon:'chicken',color:'#DB8D67',goal:'Build a caring daily routine for a small flock.',sourceIds:['chickens'],glossary:[['Hen','An adult female chicken.'],['Roost','A perch chickens use for resting.'],['Brooder','A protected warm space for chicks.']],
    quests:[
      ['Meet your flock','sequence','Arrange the growth stages.','Chickens develop from chicks into young birds and adults.','Chick|1;Young bird|2;Adult|3','Do all breeds develop at the same rate?','No|Yes|Only indoors',0,'Lifespan varies by breed, care, and individual; confirm local guidance.',0],
      ['Build a safe coop','build','Place shelter, a perch, and a nest.','A coop needs shelter, ventilation, and protection.','Shelter|Coop;Perch|Coop;Nest|Coop','What does a coop need?','Ventilation|No air at all|Only decoration',0,'Check local welfare and space guidance before keeping real chickens.',0],
      ['Choose the right feed','sort','Choose appropriate feed for the simulated flock.','Use a balanced feed suited to the birds\' age.','Suitable feed|Keep;Spoiled scraps|Leave;Clean feed|Keep','Should scraps replace balanced feed?','No|Always|Only for chicks',0,'This lesson does not provide a complete toxic-food list.',0],
      ['Fresh water','pour','Fill the drinking station.','Provide clean drinking water and keep the station maintained.','Water station|Fill','How should drinking water be available?','Regularly and reliably|Only on weekends|Never',0,'Check water more often during hot weather.',0],
      ['A clean home','sort','Put used bedding aside and choose clean bedding.','Cleaning supports a healthier living environment.','Clean bedding|Keep;Used bedding|Leave;Clean bedding|Keep','What helps keep the coop healthy?','Routine cleaning|Ignoring damp bedding|No maintenance',0,'Wash hands after contact with birds or their environment.',0],
      ['Time to grow','match','Match each bird to suitable care.','Young chicks need different care from adult hens.','Chick|Brooder care;Hen|Adult care;Young bird|Growth care','Which birds need special early care?','Chicks|Only roosters|No birds',0,'Growth is simulated; actual development varies.',10],
      ['Collect the eggs','build','Place eggs carefully into the basket.','Hens can lay eggs without a rooster.','Egg|Basket;Egg|Basket;Egg|Basket','Is a rooster required for a hen to lay?','No|Yes|Only in winter',0,'Fertile eggs require a rooster. Follow local food-safety guidance for handling.',0],
      ['Observe and protect','sort','Choose good care actions.','Watch behavior and maintain predator protection.','Check water|Keep;Inspect fencing|Keep;Ignore changes|Leave','What if a real bird seems ill?','Consult a qualified professional|Ask a game for medication|Ignore it',0,'The app cannot diagnose illness or prescribe treatments.',0]
    ] },
  { id:'garden',name:'The Garden',subject:'Plants & flowers',subtitle:'Small seeds. Wonderful possibilities.',icon:'flower',color:'#8BAE84',goal:'Grow plants by understanding their needs and stages.',sourceIds:['garden','tomato','herbs','strawberry','lettuce','marigold'],glossary:[['Germination','A seed starting to grow.'],['Transplant','A young plant moved into a growing space.'],['Mulch','Material placed on soil to help manage moisture and weeds.']],
    quests:[
      ['Choose what to grow','match','Match each plant to its harvest or bloom.','Choose a plant suited to your space and climate.','Tomato|Fruit;Basil|Leaves;Sunflower|Flower','What should guide plant choice?','Space and local climate|Only a picture|A fixed global calendar',0,'Advice in the library describes common conditions; local seasons differ.',0],
      ['A place in the sun','build','Prepare a bed with soil, light, and drainage.','Healthy growing conditions start with the site.','Soil|Bed;Sunlight|Bed;Drainage|Bed','Why consider drainage?','Roots need suitable conditions|Plants never need water|Soil must stay flooded',0,'Plant needs vary; use the selected plant profile.',0],
      ['Sow or transplant','sequence','Follow the planting sequence.','Some crops are sown directly; others often start as transplants.','Prepare|1;Plant|2;Water gently|3','Are strawberries commonly grown only from seed?','No, transplants are common|Yes, always|They have no seeds',0,'Seed depth and spacing depend on the crop and variety.',0],
      ['Water thoughtfully','pour','Water the bed gently.','Check the soil and plant instead of following one universal watering rule.','Garden bed|Fill','What should guide watering?','Soil and plant needs|Always the same amount|Flower color alone',0,'Avoid treating this simulation as an irrigation prescription.',0],
      ['The first sprout','sequence','Watch a seed become a seedling.','Germination needs suitable moisture and temperature.','Seed|1;Root|2;Seedling|3','Do all seeds sprout at the same speed?','No|Yes|Only in pots',0,'Timing varies by species, variety, and conditions.',10],
      ['Support new growth','build','Place support and space around the growing plant.','Some plants, such as many tomato varieties, benefit from support.','Support|Bed;Space|Bed;Mulch|Bed','Do all plants need a tall support?','No|Yes|Only flowers',0,'Choose care for the selected plant, not every plant identically.',0],
      ['Look before you act','sort','Choose gentle care and observation.','Inspect plants and identify the issue before acting.','Observe leaves|Keep;Hand weed carefully|Keep;Unknown chemical|Leave','What comes before choosing a pest treatment?','Identify the issue|Spray anything|Ignore instructions',0,'Ask an adult or expert about real pests and any treatment.',0],
      ['Harvest or enjoy','match','Match harvests and flowers to their plants.','Harvest indicators differ between crops.','Carrot|Root;Lettuce|Leaves;Marigold|Bloom','Should all crops be harvested the same way?','No|Yes|Only at night',0,'Seed saving depends on the crop, variety, and pollination.',0]
    ] }
];
const templates = ['match','build','sort','sequence','pour','timing'];
for (const world of worlds) {
  world.schemaVersion = 1; world.contentVersion = '1.0.0'; world.reviewStatus = 'expert-review-required';
  world.quests = world.quests.map((q,index) => {
    const [title,template,instruction,fact,items,question,answers,correct,safety,waitSeconds] = q;
    return { id:`${world.id}-${index+1}`,topicId:world.id,order:index,title,template,instruction,
      intro:`${world.goal} In this step: ${title.toLowerCase()}.`,fact,
      explorer:fact+' '+safety, items:items.split(';').map((s,i)=>({id:`item-${i}`,label:s.split('|')[0],target:s.split('|')[1]})),
      check:{question,answers:answers.split('|'),correct,explanation:fact},
      prerequisites:index?[`${world.id}-${index}`]:[],sourceIds:world.sourceIds,safety,
      realDuration:{label:waitSeconds?'Varies with species, season, and conditions':'Depends on the task and equipment',conditions:'This is an educational simulation, not a fixed biological timetable.',sourceIds:world.sourceIds},
      gameDurationSeconds:waitSeconds,gardenPaceSeconds:waitSeconds?3600:0,reward:{xp:30,coins:10},
      videoUrl:null,assetRefs:[world.icon],accessibilityAlternative:'Use the labeled controls below the scene.' };
  });
  writeFileSync(`${out}/${world.id}.json`,JSON.stringify(world,null,2)+'\n');
}
const plants = [
  ['tomato','Tomato','tomato','Warm season','Sunny position','Check root-zone moisture; keep watering consistent.','Seedling → leafy growth → flowers → fruit','Look for variety-appropriate ripe fruit.','Many varieties benefit from support.'],
  ['sunflower','Sunflower','garden','Usually warm season','Sunny position','Check soil moisture during establishment.','Seed → seedling → stem → bud → flower','Enjoy the bloom; seed maturity is a later stage.','Timeline varies by variety; research the seed packet locally.'],
  ['mint','Mint','herbs','Depends on climate','Sun or suitable partial shade','Maintain suitable moisture and drainage.','Young plant → stems → leaves','Pick suitable leaves as the plant establishes.','Mint can spread; a container can help manage it.'],
  ['carrot','Carrot','garden','Often cool season','Sunny position','Maintain moisture while establishing.','Seed → seedling → leafy top → developing root','Check variety-specific root maturity.','Prepare suitable soil; variety and soil influence root development.'],
  ['strawberry','Strawberry','strawberry','Variety and climate dependent','Sunny position','Check moisture while fruit is developing.','Transplant → established plant → flower → fruit','Pick fully ripe fruit.','Home growing commonly begins with transplants.'],
  ['marigold','Marigold','marigold','Usually warm season','Sunny position','Avoid persistently waterlogged soil.','Seedling → branches → buds → flowers','Enjoy flowers rather than assuming they are food.','Marigold is a common name; do not assume every flower is edible.'],
  ['lettuce','Lettuce','lettuce','Often cool season','Sun with climate-dependent protection','Check soil moisture regularly.','Seedling → leaves → harvestable plant','Harvest leaves or heads as appropriate to the type.','Heat can encourage bolting.'],
  ['basil','Basil','herbs','Warm season','Sunny position','Check moisture and provide drainage.','Seedling → branches → leaves','Pick suitable leaves as growth establishes.','Protect from unsuitable cold conditions.']
].map(([id,name,source,season,sun,water,timeline,harvest,note])=>({id,name,sourceIds:[source],season,sun,water,timeline,harvest,note,duration:'Variety- and climate-dependent; follow local guidance.',gameGrowthSeconds:{tomato:60,sunflower:45,mint:25,carrot:50,strawberry:65,marigold:40,lettuce:30,basil:35}[id],gardenPaceSeconds:3600,reviewStatus:'expert-review-required'}));
writeFileSync(`${out}/plants.json`,JSON.stringify(plants,null,2)+'\n');
writeFileSync(`${out}/sources.json`,JSON.stringify(sources,null,2)+'\n');
writeFileSync(`${out}/manifest.json`,JSON.stringify({schemaVersion:1,contentVersion:'1.0.0',topics:worlds.map(w=>w.id),plants:'plants.json',sources:'sources.json'},null,2)+'\n');
console.log('Authored 32 quests across four worlds and eight plant profiles.');

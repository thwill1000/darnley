#charset "us-ascii"

//
// TODO
//

/*
 * 1) Add CALL and DISMISS verbs for summoning and dismissing the suspects from
 *    the dining room
 * 2) Investigate how to get the room description to say "a, b and c are WAITING here"
 *    instead of STANDING here
 * 3) Once they've been called suspects should follow you around
 * 4) Calling a new suspect should dismiss the old one
 */

/*
 *   Copyright (c) 1999, 2002 by Michael J. Roberts.  Permission is
 *   granted to anyone to copy and use this file for any purpose.  
 *   
 *   This is a starter TADS 3 source file.  This is a complete TADS game
 *   that you can compile and run.
 *   
 *   To compile this game in TADS Workbench, open the "Build" menu and
 *   select "Compile for Debugging."  To run the game, after compiling it,
 *   open the "Debug" menu and select "Go."
 *   
 *   Please note that this file contains considerably more than the
 *   minimal set of definitions necessary to create a working game; this
 *   file has numerous examples meant to help you start making progress on
 *   your game more quickly, by giving you a few concrete examples that
 *   you can copy and modify.  As you flesh out your game, you should
 *   modify the objects we define here, or simply remove them when you no
 *   longer need them in your game.
 *   
 *   If you want a truly minimal set of definitions, create another new
 *   game in TADS Workbench, and choose the "advanced" version when asked
 *   for the type of starter game to create.  
 */

/* 
 *   Include the main header for the standard TADS 3 adventure library.
 *   Note that this does NOT include the entire source code for the
 *   library; this merely includes some definitions for our use here.  The
 *   main library must be "linked" into the finished program by including
 *   the file "adv3.tl" in the list of modules specified when compiling.
 *   In TADS Workbench, simply include adv3.tl in the "Source Files"
 *   section of the project.
 *   
 *   Also include the US English definitions, since this game is written
 *   in English.  
 */
#include <adv3.h>
#include <en_us.h>

/*
modify Fixture
    cannotTakeMsg = 'You take note of {the dobj/him}, but see little
        point in carrying {that dobj/him} around with you.'
;
*/
    
class StaticClue: Fixture
    cannotTakeMsg = 'You take note of {the dobj/him}, but see little
        point in carrying {that dobj/him} around with you.'    
;


/*
 *   Our game credits and version information.  This object isn't required
 *   by the system, but our GameInfo initialization above needs this for
 *   some of its information.
 *   
 *   IMPORTANT - You should customize some of the text below, as marked:
 *   the name of your game, your byline, and so on.  
 */
versionInfo: GameID
    name = 'The Sealed Room Murder'
    byline = 'by Jim & Tom Williams'
    htmlByline = 'by <a href="mailto:thwill@ntlworld.com">
                  Tom Williams</a>'
    version = '0.1'
    authorEmail = 'Tom Williams <thwill@ntlworld.com>'
    desc = 'CUSTOMIZE - this should provide a brief description of
           the game, in plain text format.'
    htmlDesc = 'CUSTOMIZE - this should provide a brief description
                of the game, in <b>HTML</b> format.'

    showCredit()
    {
        /* show our credits */
        "Put credits for the game here. ";

        /* 
         *   The game credits are displayed first, but the library will
         *   display additional credits for library modules.  It's a good
         *   idea to show a blank line after the game credits to separate
         *   them visually from the (usually one-liner) library credits
         *   that follow.  
         */
        "\b";
    }
    showAbout()
    {
        "Put information for players here.  Many authors like to mention
        any unusual commands here, along with background information on
        the game (for example, the author might mention that the game
        was created as an entry for a particular competition). ";
    }
;

//
// Front Gate
//
frontGate: OutdoorRoom 'Front Gate'
    "From a pair of splendid wrought iron gates the drive runs north
    towards the main house. To the east you can see a stableyard,
    and to the west a lawn. The snow covered drive reveals several
    footprints. "
    
    north = drive
    east  = stables
    south : FakeConnector {"You contemplate leaving the investigation to somebody else, but think better of it. "} 
    west  = westLawn
;

+ Decoration 'wrought iron gates'
    'gates'
    "A pair of splendid wrought iron gates. "

    isPlural = true
;

+ Fixture 'footprints'
    'footprints'
    "The prints from men's hobnailed boots go between the west lawn and stables. "

    isPlural = true
;    
    
//
// The Drive
//
drive: OutdoorRoom 'The Drive' 'the drive'
    "The drive ends at a flight of steps leading up to the principal
     entrance of the house, flanked by a pair of stone lions.
     A gravel path leads east-west across the front of the house
     from a statue lined avenue to a tennis court.
     The snow reveals a mass of footprints. "

    north = hall
    east  = avenueOfStatues
    west  = gravelPath
    south = frontGate
    in asExit(north)
    up asExit(north)
;

+ Decoration 'stone lions'
    'lions'
    "A pair of stone lions. "

    isPlural = true
;

+ Decoration 'house/mansion'
    'house'
    "TODO: Write a description. "
;

+ Fixture 'footprints'
    'footprints'
    "The prints from flat footed boots go east and west along the gravel path
     in front of the house. Slipper prints come from the house and head east
     and west along the path. Prints from men's shoes come from the house and
     go west. Prints from lady's shoes head to and from the frontdoor and west
     along the gravel path. "

    isPlural = true
;

//
// The Hall
//
hall: Room 'Hall'
    "The walls of the hall are decorated with swords and Civil War armour.
     The floor is marble. The only furniture is a glass case containing
     various flints and shards of pottery. At the far end of the hall, two
     sets of fine armour stand either side of the stairs which have
     barley-sugar bannisters and carved pineapple finials.
     Doors lead west into the study, east into the dining room,
     southwest into the drawing room and southeast into the music room.
     You notice that the door leading into the study is ill-fitting with a gap
     of about two centimetres at the bottom. "

    east      = diningRoom
    west      = study
    south     = drive
    southeast = musicRoom
    southwest = drawingRoom
    up        = landing
    down        asExit(south)
    out         asExit(south)
;

+ Fixture, Container 'armor/armour'
    'armour'
    "A suit of Civil War three-quarter armour with closed helmet. "
    
    dobjFor(LookIn) {
        action {
            if (revolver.moved) {
                inherited;
                exit;
            }
            revolver.moveInto(self);
            "A revolver is concealed in the helmet. ";
            addToScore(1, 'finding the revolver');
        }
    }
;

/*
+ Fixture 'door mat'
    'door mat'
    "The door mat is damp from melted snow and shows traces of mud
    and gravel. "
;
*/

+ Fixture 'display case'
    'display case'
    "According to a label at the front of the case these flints and shards of
    pottery were found in the grounds of the house. "
;

revolver : Thing 'gun/revolver'
    'revolver'
    "The revolver found in the hall is a Webley-Fosbery .455 service
    revolver. One bullet has been discharged from it. "
;

//
// Colonel Darnley's Study
//
study: Room 'Colonel Darnley\'s Study' 'Colonel Darnley\'s study'
    "Colonel Darnley's body lies on a turkey carpet in the middle of the
     study. A port glass is by his body and a tantalus of port stands on
     a table. The room is panelled and contains several club-chairs, some
     glass cases holding stuffed birds and a writing table on which there 
     are various sporting magazines and a rack of sporting
     guns and pistols. As you walk on the floor by the french window in
     the west wall, you feel broken glass underfoot."
    
    east  = hall
    south = drawingRoom
;

+ colonelDarnley: Fixture 'colonel darnley/body/corpse'
    'Colonel Darnley\'s body'
    "The body is dressed in a smoking jacket open at the chest. There is a
    bloody bullet wound in the front of the dress-shirt. The bullet has not
    passed through the body. Evidently the Colonel had got out of his chair
    on hearing or seeing his murderer. The impact of the bullet had
    caused him to spin and fall and the furniture had got in the way,
    further deflecting the body. It is no longer possible to tell the direction
    of the shot. "

    isKnown = true
    isProperName = true
    
    cannotTakeMsg = 'It would be inappropriate, not to say difficult to carry
        Colonel Darnely\'s body around with you.'
;

+ StaticClue '(wine) (port) glass'
    'port glass'
    "The port glass is one of a set engraved with the words \'Floreat
    Darnley\'. A crust of dried liquid is at the bottom and lip marks on the
    rim though no trace of lipstick. "
;

+ StaticClue 'tantalus/port'
    'tantalus of port'
    "The tantalus is made of cherrywood. It holds an empty decanter
    with a silver label marked 'Brandy' and a half full decanter marked
    'Port'. The decanters are normally inacessible since they are held
    in place by a sort of \'lid\' of wood which is fastened by a small
    lock. The key is in the lock. "
;

+ letter: Thing 'letter'
    'letter'
    "The letter is an incomplete draft : \'Dear Sir, I have considered your
    monstrous suggestion and find I cannot ... "
    
    initSpecialDesc = "There is also a letter on the writing table. "
;

+ StaticClue 'rack/guns/pistols'
    'rack of guns'
    "One of the pistols is missing from this rack. "
    
    cannotTakeMsg = 'You take note of {the dobj/him}, but see little
        point in carrying them around with you.'
;

+ Fixture '(french) window'
    'french window'
    "One pane is smashed. The glass on the floor is apparently from this. "
;

+ StaticClue '(window) glass'
    'window glass'
    "This glass is apparently from the smashed french window. "
;

//
// The Drawing Room
//
drawingRoom: Room 'The Drawing Room' 'the drawing room'
    "The centerpiece of the drawing room is a three piece suite on a Chinese
     carpet. There are several tables holding magazines and novels
     marked with bookmarks. Recent family portraits are on the walls.
     The fireplace is carved and holds the remains of a fire. On the
     mantlepiece is an Indian rosewood box with an ivory inlay. The
     room smells of stale cigar smoke. A heavy door leads north into
     the study. "
    
    north = study
    east  = hall
;

//
// Dining Room
//
diningRoom: Room 'Dining Room'
    "The dining room holds a fine oak table with chairs in William and Mary
     style. A glass case contains various pieces of Delft pottery. A
     sideboard holding a silver wine cooler and a pair of Sevres porcellain
     urns stand against one wall. The fireplace is of carved marble and the
     walls hold various Italian landscapes. "
    
    northeast = butlersPantry
    southeast = billiardRoom
    southwest = musicRoom
    west      = hall
;

//
// Music Room
//
musicRoom: Room 'Music Room'
    "In the centre of the music room is a piano and, on top, a brass ashtray
     with the stub of a cigar in it. There are several chairs, a music stand
     and in one corner a large harp with broken strings. The room is elegant
     but neglected."
    
    north = diningRoom
    west  = hall
;

+ Thing 'cigar stub'
    'cigar stub'
    "This cigar stub is a straight dark cylinder rather than the
    conventional shape. That and the tarry appearance suggest a cheroot. "
;

+ musicRoomPiano: Fixture 'piano'
    'piano'
    "The sheets of music on the piano are for duets. "
;

//
// Butler's Pantry
//
butlersPantry: Room 'Butler\'s Pantry'
    "The butler's pantry is laid out as a sitting room with a bed behind a
     curtain. Two temporary beds have been made up. There is a small
     bookshelf. The room suggests a clean, neat bachelor with no pretensions."
    
    south = diningRoom
    west  = kitchen
;

+ Fixture '(book) shelf/bookshelf'
    'bookshelf'
    "The bookshelf contains books on self-improvement and domestic accounts. "
;


//
// Billiard Room
//
billiardRoom: Room 'Billiard Room'
    "A full size table occupies the centre and on the wall a board indicates
     the result of a game. There is a small bookcase holding magazines and
     several novels by Conan Doyle and Buchan. On top of the bookcase are
     three wine glasses and an ashtray. The walls are decorated with sporting
     prints. "
    
    north = diningRoom
;

+ Fixture 'wine glasses'
    'wine glasses'
    "The three wine glasses are all dirty. "
;

+ Fixture 'ashtray'
    'ashtray'
    "The ashtray contains the remains of three cigars, one Havana and
    two cheroots. "
;

//
// Kitchen
//
kitchen: Room 'Kitchen'
    "The kitchen has game birds hanging from the ceiling and the usual kitchen
     furniture. By the outside door is
     a line of boots and some cleaning brushes and polish. "
    
    east  = butlersPantry
    north = kitchenGarden
;

+ knife: Thing '(kitchen) knife'
    'kitchen knife'
    "This kitchen knife is stained with blood. "
    
    initSpecialDesc = "On the sink draining-board is a knife. "
;

+ boots: Fixture 'boots'
    'boots'
    "All these boots are polished clean except for a mud stained pair that
    apparently belong to Sir Redvers Slingsby. "
;

//
// Landing
//
landing: Room 'Landing'
    "The landing walls hold some fine antlers and animal heads and some bad
     portraits of the Darnley ancestors. Examination of the latter makes one
     wonder how the family reproduced. "
    
    north = bathroom
    east  = servantsQuarters
    south = morningRoom
    west  = milicentsRoom
    down  = hall
;    

//
// Bathroom
//
bathroom: Room 'Bathroom'
    "The bathroom contains an enamelled cast iron bath with claw feet
    and a toiler bearing a brass tablet calling it 'The Imperial Avenger'.
    A washstand with a marble top and a pedestal washbowl complete
    the ensemble. Various toiletries are scattered around in the normal
    way."
    
    south = landing
;

//
// Servants' Quarters
//
servantsQuarters: Room 'Servants\' Quarters'
    "The servants' quarters consist of a single room with two single beds,
     a rail for hanging clothes on behind a curtain, a wash stand and a
     chest of drawers. On the chest is a bundle of correspondence and various
     framed photographs. A gentleman's country-suit with a newspaper in the
     pocket is hanging on the rail amongst the dresses and a pipe is on the
     washstand. The walls are decorated with framed needlework eg.
     'Bless this House'. "

    west = landing
;

+ Fixture 'letters/correspondence'
    'correspondence'
    "These letters are all from Mrs. Goodbody's nephew. "

    isPlural = true
;

+ Fixture 'photos/photographs'
    'photographs'
    "These photographs depict Mrs. Goodbody's various ugly relatives. "

    isPlural = true
;

+ Fixture '(gentleman\'s) (gentlemans) suit'
    'suit'
    "This gentleman's country-suit is apparently Sir Redvers. "
;

+ Fixture 'paper/newspaper'
    'newspaper'
    "One headline on the front page catches your eye -
    \'Collapse of Rio Plata Mining Co. - Our co-respondent in Lima, Peru
    reports the collapse of several silver mining companies through the
    fraud of their directors. These frauds are expected to cause heavy
    loss to British investors.\' "
;

+ Thing 'pipe'
    'pipe'
    "The pipe is in the style called \'calabash\' with a meerschaum bowl and
    amber mouthpiece. "
;

//
// Morning Room
//
morningRoom: Room 'Morning Room'
    "The morning room holds a chintz sofa and an occasional table with
     magazines and books. Against one wall is a piano. On a table stands
     a gramophone. There are various pictures, mainly watercolours of birds. "
    
    north = landing
    west  = masterBedroom
    east  = guestRoom
;

+ gramophone: Fixture 'gramophone'
    'gramophone'
    "It has a device for playing several records in sequence. All the
    records are Chopin. "
;

+ morningRoomPiano: Fixture 'piano'
    'piano'
    "There are several sheets of Schubert Lieder music on the piano's music
    stand. "
;

//
// Milicent's Room
//
milicentsRoom: Room 'Milicent Darnley\'s Bedroom' 'Milicent Darnley\'s bedroom'
    "Milicent Darnley\'s bedroom is decorated to a young lady's taste
     with a bed, wardrobe, dressingTable and a small writing table.
     The surfaces are covered with small ornaments, mainly of dogs
     and the walls have pictures of favourite pets."
    
    east  = landing
    south = masterBedroom
;

//
// Master Bedroom
//
masterBedroom: Room 'Master Bedroom'
    "Colonel and Mrs. Darnley\'s bedroom is heavily panelled and reflects
     the Colonel's tastes, with sporting prints and a humidor of cigars.
     There is a double bed, a dressing table, wardrobe and trouser press.
     A small bathroom is attached. It is striking that Sarah Darnley has
     had so little impact on the decoration."
    
    north = milicentsRoom
    east  = morningRoom
;

+ Fixture '(double) bed'
    'double bed'
    "This double bed has not been slept in. "
;

+ Fixture 'wardrobe'
    'wardrobe'
    "As well as clothes the wardrobe contains a selection of
    men's and women's shoes. "
;

+ Fixture 'cigars'
    'cigars'
    "The cigars are Burmah cheroots. "

    isPlural = true
;

+ Fixture '(dressing) table'
    'dressing table'
    "There is nothing of note on the dressing table. "
;

+ Fixture 'shoes'
    'shoes'
    "This selection of mens and womens shoes is unremarkable. One set of
    lady's shoes is mud-stained. "
;

//
// Guest Room
//
guestRoom: Room 'Guest Room'
    "A guest-room decorated in blue with wardrobe, bed, washstand and
     writing-table. By the bed is a pair of men's slippers. On the writing
     table is a pack of cigarettes and some stationery and pens."
    
    west = morningRoom
;

+ slippers: Fixture 'slippers'
    'slippers'
    "The slippers are slightly damp and stained with mud. "
    isPlural = true
;

+ cigarettes: Thing 'cigarettes'
    'cigarettes'
    "These cigarettes are an expensive brand by Fribourg & Freyer. "
    isPlural = true
;

//
// Kitchen Garden
//
kitchenGarden: OutdoorRoom 'Kitchen Garden'
    "The kitchen garden is full of frozen vegetables lying under snow.
     The house lies  to the south and can be entered via the kitchen door.  
     A gravel path leads west to an orchard and east to some outhouses.
     Various footprints are visible in the snow. "
    
    east  = outhouses
    south = kitchen
    west  = orchard
;

+ Fixture 'footprints'
    'footprints'
    "Both flat footed boot prints and slipper prints can be seen going
    between the kitchen and the maze. "

    isPlural = true
;

//
// Outhouses
//
outhouses: OutdoorRoom 'Outhouses' 'some outhouses'
    "This section of the garden contains various outhouses; a laundry,
     a coal store and a pigeon coop. The gravel path leads west around
     the back of the house to the kitchen garden and south to a box hedge
     maze. "
    
    west  = kitchenGarden
    south = maze
;

//
// Maze
//
maze: OutdoorRoom 'Maze'
    "Situated on the east side of the house, the maze consists of low
     box hedges. The gravel path leads north to some outhouses and
     south towards the front of the house and the east lawn.
     The marks in the snow cannot be deciphered into footprints."

    north = outhouses
    south = eastLawn
;

//
// East Lawn
//
eastLawn: OutdoorRoom 'East Lawn'
    "A square expanse of snow covered lawn to the southeast of the house.
     The gravel path around the house leads north to a box hedge maze and
     west through an avenue of statues towards the main door.
     Southwest across the lawn you can see a stableyard, to the southeast
     a narrow path leads to a small cottage.
     The smooth covering of snow is broken by footprints. "
    
    west      = avenueOfStatues
    north     = maze
    southwest = stables
    southeast = cottage
;

+ Fixture 'footprints'
    'footprints'
    "The prints from flat footed boots and men's slippers are visible in the
    snow heading around the corner of the house, to and from the maze and 
    avenue of statues. Whereas the prints from hob-nailed boots can be seen
    in the snow going east to west between the stables and the cottage. "
    
    isPlural = true
;

//
// Avenue of Statues
//
avenueOfStatues: OutdoorRoom 'Avenue of Statues'
    "This gravel path runs east-west across the front of the house flanked
     by an avenue of statues. The snow covered gravel is too rough to
     distinguish footprints. "

    east  = eastLawn
    west  = drive
;

+ Fixture 'footprints'
    'footprints'
    "The snow covered gravel is too rough to distinguish footprints. "
    
    isPlural = true
;

//
// Stables
//
stables: OutdoorRoom 'Stables'
    "The stables are falling into disrepair. One part contains Colonel
     Darnley's bay hunter. The other garages a large Daimler. The yard
     is full of straw and oil spills, and is crossed by footprints. The
     tack room holds the saddle and gear for the horse.
     The main drive lies to the west and a square expanse of snow
     covered lawn to the east. "
    
    west = frontGate
    east = eastLawn
;

+ Fixture 'footprints'
    'footprints'
    "The prints from hob-nailed boots can be seen in the snow going between
    the drive and the east lawn. "
    
    isPlural = true
;

//
// Gamekeeper's Cottage
//
cottage: Room 'Gamekeeper\'s Cottage'
    "In the damp shade of some chestnut trees is a gamekeeper's cottage
    tucked against the south-east corner of the park. The door of the
    cottage is open and footprints are visible across the threshold. Inside
    are various items of game, two shotguns on the wall, a table covered
    by oil cloth, an unmade bed, a slop-stone sink and an open fire with a
    pot hanging over it. The place is very dirty; the hearth is littered
    with foodscaps, the ends of cigarettes and newspapers."

    northwest = eastLawn
;

+ Fixture 'cigarette ends'
    'cigarette ends'
    "These cigarette ends come from a cheap, mass produced brand. "

    isPlural = true
;

//
// Orchard
//
orchard: OutdoorRoom 'Orchard' 'an orchard'
    "The park wall lies north and has several pear-trees trained in
    espalier against it. There are a large number of apple trees, but no
    fruit. The gravel path around the house leads east to the kitchen
    garden and south onto the terrace.
    There are various marks on the ground, too unclear to be sure
    that they are footprints. "

    east = kitchenGarden
    south = terrace
;

+ Fixture 'footprints'
    'footprints'
    "There are various marks on the ground, too unclear to be sure
    that they are footprints. "

    isPlural = true
;

//
// Terrace
//
terrace: OutdoorRoom 'Terrace'
    "From the house a french window leads onto this paved terrace, which
    shows traces of many footprints in the snow. The french window is
    open and has a broken pane. At the western end of the terrace is an
    ornamental pond. "
    
    north = orchard
    east  = study
    south = westSide
    west  = pond
;

+ Fixture '(french) window'
    'french window'
    "One of the panes is smashed, but there is no glass on the terrace. The
    window lock shows that it cannot be locked or unlocked from outside. "
;

+ Fixture 'footprints'
    'footprints'
    "A mess of footprints including boots, slippers and some shoe prints. "

    isPlural = true
;

//
// Ornamental Pond
//
pond: OutdoorRoom 'Ornamental Pond'
    "An ornamental pond stands at the western end of the terrace.
    The pond is covered in ice. In the four corners of the pond are
    stone pedestals. These hold statues."
    
    east = terrace
;

+ Decoration 'ornamental pond'
    'ornamental pond'
    "Near the centre of the pond the ice is thinner as it has frozen again 
    after having been broken. Beneath the ice you can see the missing statue
    from the fourth pedestal. "
;

+ missingStatue: Fixture 'missing sunken statue'
    'sunken statue'
    "The statue that is beneath the ice belongs to the same set as those on
    the pedestals. It is a figure of Autumn crowned in grapes and wheatsheaves. "
;

+ cherootInPond: Thing 'cigar cheroot butt/stub'
    'cheroot butt/stub'
    "This damp cigar stub was found in the pond. It is a straight dark
    cylinder rather than the conventional shape. That and the tarry
    appearance suggest a cheroot. "
;

+ Decoration 'statues'
    'statues'
    "The statues form a set of four, representing the Four Seasions. They 
    are of Italian marble and rest on their own weight rather than being
    cemented to their plinths. Some strength would be required to move
    one. "

    isPlural = true
;

+ Fixture 'footprints'
    'footprints'
    "Only one set of footprints can be made out in the snow. They are of
    flat footed bootprints coming to and from the terrace. "
    
    isPlural = true
;

//
// West Side of the House
//
westSide: OutdoorRoom 'West Side of the House'
    "The gravel path around the house passes between the smooth snow
    covered tennis court and a bed of withered flowers covered in snow.
    The gable of the hosue shows cruck posts, indicating a 15th century
    origin.
    The path leads north onto the terrace and east around the front of
    the house.    
    Various footprints are visible in the snow."

    north     = terrace
    east      = gravelPath
    southwest = summerHouse
;

+ Fixture 'footprints'
    'footprints'
    "There are slipper prints, flat-footed boot prints and some shoe prints
    heading to and from the terrace and the front of the house. "
    
    isPlural = true
;

//
// Gravel Path
//
gravelPath: OutdoorRoom 'Gravel Path'
    "A gravel path leading from the drive to the east, across the front
    of the house towards a tennis court. To the south is a snow covered
    lawn. "
    
    east  = drive
    south = westLawn
    west  = westSide
;

//
// West Lawn
//
westLawn: OutdoorRoom 'West Lawn'
    "Between the summer house and the drive is a lawn. It is planted with
    a few sapling and the covering of snow shows footprints. "
    
    east      = drive
    west      = westSide
    southwest = summerHouse
;

+ Fixture 'footprints'
    'footprints'
    "Prints from lady's shoes and men's hob-nailed boots can be seen in the
    snow going between the drive and the summer house. "
    
    isPlural = true
;

//
// Summer House
//
summerHouse: Room 'Summer House'
    "A wooden summer house stands on a patch of lawn. Inside can be
    seen some croquet mallets and hoops, several cigarette ends and
    a handkerchief. A bale of straw has been spread out and suggests
    that a tramp - or someone else - has slept there. "
    
    northeast = westSide
    east      = westLawn
;

+ Fixture 'cigarette ends'
    'cigarette ends'
    "These cigarette ends come from a cheap, mass produced brand. "
    
    isPlural = true
;

+ handkerchief: Thing 'handkerchief/hanky'
    'handkerchief'
    "This is a lady's hanky found in the summer house.
    It is plain lace edged and perfumed. "
;

tMurder: Topic '(colonel) (darnley\'s) murder';
tCrime:  Topic 'crime';
tEventsOfYesterday: Topic 'yesterday\'s events yesterday';
tAlibi:  Topic 'his her alibi';
tFlatfootedBootPrints: Topic 'flat footed bootprints';
tHobnailedBootPrints:  Topic 'hob nailed bootprints';
tSlipperPrints:        Topic 'slipper prints';
tMensShoePrints:       Topic 'mens shoe foot prints';
tWomensShoePrints:     Topic 'womens shoe foot prints';
tLadysShoes:           Topic 'ladys ladies womens shoes';
tNewspaperArticle:     Topic 'newspaper article';

/* 
 *   Entryway location.
 *   
 *   We use the class "Room" to define the location.  Room is a class,
 *   defined in the library, that can be used for most of the locations in
 *   the game.
 *   
 *   Our definition defines two strings.  The first string, which must be
 *   in single quotes, is the "name" of the room; the name is displayed on
 *   the status line and each time the player enters the room.  The second
 *   string, which must be in double quotes, is the "description" of the
 *   room, which is a full description of the room.  This is displayed
 *   when the player types "look around," when the player first enters the
 *   room, and any time the player enters the room when playing in VERBOSE
 *   mode.  
 */
entryway: Room 'Entryway'
    "This large, formal entryway is slightly intimidating:
    the walls are lined with somber portraits of gray-haired
    men from decades past; a medieval suit of armor<<describeAxe>>
    towers over a single straight-backed wooden chair.  The
    front door leads back outside to the south.  A hallway leads
    north. "

    /*
     *   In the description text above, we embedded the expression
     *   "describeAxe".  Whenever the description text is displayed, it
     *   will call evaluate that expression, which will in turn call this
     *   method, where we'll generate some additional text to describe the
     *   axe if it's still part of the suit of armor. 
     */
    describeAxe
    {
        if (axe.isIn(suitOfArmor))
            ", posed with a battle axe at the ready,";
    }

    /* 
     *   To the north is the hallway.  Set the "north" property to the
     *   destination room object.  Other direction properties that we
     *   could set: east, west, north, up, down, plus the diagonals:
     *   northeast, northwest, southeast, southwest.  We can also set "in"
     *   and "out", and the shipboard directions port, starboard, fore,
     *   and aft.  
     */
    north = hallway

    /*
     *   To the south is the front door.  A travel direction link can
     *   point directly to another room, but it can also point to
     *   something like a door.  
     */
    south = frontDoor

    /*
     *   The "out" direction is the same as south, since going south leads
     *   outside 
     */
    out = frontDoor
;

/*
 *   Define the front door.  The "+" sign in front of the definition means
 *   that the object is located within the most recently defined room,
 *   which in this case is 'entryway' as defined above.
 *   
 *   We start this object definition with two strings, both in single
 *   quotes, and a third in double quotes.  The first is the vocabulary
 *   list for the object, which tells us how the player can refer to this
 *   object.  The second string is the name, which is how the game refers
 *   to the object in generated messages.  The third is the full
 *   description of the object, which is displayed when the player
 *   examines this object.
 *   
 *   The vocabulary list consists of any number of words separated by
 *   spaces.  Every word is an adjective except the last, which is a noun.
 *   You can specify more than one noun by listing several nouns separated
 *   by slash characters ("/").  The player can use any of the words
 *   defined here to refer to the object - the player doesn't have to use
 *   all of the words, or use them in the same order that we define them
 *   here, except that adjectives and nouns must be in the grammatically
 *   correct order (in English, this means that adjectives must precede
 *   nouns).  
 */
+ frontDoor: Door 'front door' 'front door'
    "It's a heavy wooden door, currently closed. "

    /* the door is initially closed */
    initiallyOpen = nil

    /*
     *   Doors can usually be opened, but we don't want to allow this one
     *   to be opened.  The library by default allows a door to be opened
     *   and closed at will.  To change this, we must override the "direct
     *   object" handler for the Open action on this object.  Since we
     *   don't want anything to happen when the player tries to open the
     *   door, we can simply override the action handler and display a
     *   message indicating why we can't open the door.  
     */
    dobjFor(Open)
    {
        action() { "You'd rather stay in the house for now. "; }
    }
;

/*
 *   Define the chair.  We use the Chair class for this.  Note that the
 *   default Chair class defines a moveable object; we don't want our chair
 *   going anywhere, so make it use the Immovable class as well.
 *   
 *   We don't need to refer to the chair anywhere, so we don't bother
 *   giving it a name.  This saves us a little typing and saves us the
 *   trouble of thinking of a name for the object.  
 */
+ Chair, Immovable 'straight-backed wooden chair' 'wooden chair'
    "It looks like one of those formal chairs that looks elegant
    but is incredibly uncomfortable to sit on. "
;

/*
 *   Define the suit of armor.  It can't be moved because it's very heavy,
 *   so make it a Heavy object.  Note that we do need to refer to this
 *   object (in the 'entryway' object), so we need to give it an object
 *   name.
 *   
 *   Note that we define both "suit" and "armor" as nouns in our vocabulary
 *   list, because we want to be able to refer to it as "suit of armor"; in
 *   the phrasing "x of y", both x and y are noun phrases.  
 */
+ suitOfArmor: Heavy 'medieval plate-mail suit/armor' 'suit of armor'
    "It's a suit of plate-mail armor that looks suitable for
    a very tall knight. <<describeAxe>> "

    /* 
     *   as we did in entryway's description, we've embedded a call to our
     *   describeAxe method, so that we can add a description of the axe
     *   if appropriate 
     */
    describeAxe
    {
        if (axe.isIn(self))
            "The armor is posed with a huge battle-axe held
            at the ready. ";
    }
;

/*
 *   The battle axe, initially posed with the suit of armor.  We make this
 *   a Thing, because we want it to be something the player can pick up
 *   and manipulate.
 *   
 *   This definition starts with two "+" signs, to indicate that it is
 *   initially inside the last object defined with one "+" sign, which is
 *   the suit of armor.
 *   
 *   Note that we define a bunch of vocabulary words that aren't really
 *   synonyms for "axe," but are for things we describe as parts of the
 *   axe (the blade, the dried blood on the blade).  Those parts aren't
 *   worth defining as separate objects, but we can at least recognize
 *   them as vocabulary words that simply refer to the axe itself.  
 */
++ axe: Thing 'large steel battle dried ax/axe/blade/edge/blood' 'battle axe'
    "It's a large steel battle axe.  A little bit of dried blood on
    the edge of the blade makes the authenticity of the equipment
    quite credible. "

    /* 
     *   When we're located in the suit of armor, the suit of armor and
     *   the room containing the suit of armor describe us specially.
     *   This means that we do not want to display our name among the
     *   miscellaneous items listed in the room's description.  To prevent
     *   being listed in the ordinary description, indicate that we have a
     *   "special" description any time we're located in the suit of
     *   armor, and then make this special desription show nothing - it's
     *   not necessary to show anything because the room and suit of armor
     *   both already show something special for us.  
     */
    useSpecialDesc = (isIn(suitOfArmor))
    specialDesc = ""
;
    
/*
 *   Define the portraits.  We don't want to define several individual
 *   portraits, because they're not important enough, so define a single
 *   object that refers to the portraits collectively.
 *   
 *   Because the library normally allows the player to abbreviate any word
 *   to its first six or more letters, note that we don't have to provide
 *   separate vocabulary words for "portrait" and "portraits", or for
 *   "picture" and "pictures" - "portrait" is an acceptable abbreviation
 *   for "portraits".  
 */
+ Fixture 'somber gray-haired portraits/pictures/men/man' 'portraits'
    "The men in the portraits look like bankers or businessmen, all
    serious faces and old-fashioned suits. "

    /* 
     *   this object has a plural name, so we must set the isPlural flag
     *   to let the library know how to use its name in messages 
     */
    isPlural = true
;

/*
 *   The hallway, north of the entryway.  
 */
hallway: Room 'Hallway'
    "This broad, dimly-lit corridor runs north and south. "

    south = entryway
    north = kitchen
;

/*
 *   The kitchen.
 */
kitchen2: Room 'Kitchen'
    "This is a surprisingly cramped kitchen, equipped with
    antique accoutrements: the stove is a huge black iron contraption,
    and in place of a refrigerator is an actual icebox.  A hallway
    lies to the south. "

    south = hallway
;

/*
 *   The stove is a Fixture, since we don't want the player to be able to
 *   move it.  It's also an OpenableContainer, because we want the player
 *   to be able to open and close it and put things in it.
 *   
 *   Note that we define 'stove' as both an adjective and as a noun,
 *   because we want the player to be able to refer to it not only as a
 *   "stove" but also as a "stove door".
 *   
 *   Because we're an OpenableContainer, the library will automatically add
 *   to our description text an open/closed indication and a listing of any
 *   contents when we're open.  
 */
+ Fixture, OpenableContainer
    'huge black iron stove stove/oven/contraption/door' 'stove'
    "It's a huge black iron cube, with a front door that swings
    open sideways. "

    /* it's initially closed */
    initiallyOpen = nil
;

/*
 *   Put a loaf of bread in the stove.  It's edible, so use the library
 *   class Food. 
 */
++ Food 'fresh golden-brown brown loaf/bread/crust' 'loaf of bread'
    "It's a fresh loaf with a golden-brown crust. "

    /* 
     *   we want to provide a special message when we eat the bread, so
     *   override the direct object action handler for the Eat action;
     *   inherit the default handling, but also display our special
     *   message, which will automatically override the default message
     *   that the base class produces 
     */
    dobjFor(Eat)
    {
        action()
        {
            /* inherit the default handling */
            inherited();

            /* show our special description */
            "You tear off a piece and eat it; it's delicious.  You tear off
            a little more, then a little more, and before long the whole loaf
            is gone. ";
        }
    }
;

/*
 *   The icebox is similar to the stove.
 */
+ Fixture, OpenableContainer 'ice box/icebox' 'icebox'
    "Before there were refrigerators, people had these: it's just
    a big insulated box, into which one would put perishables
    along with enough ice to keep the perishables chilled for a few
    days. "

    /* 
     *   when looking in the icebox, explicitly point out that it contains
     *   no ice; do this by overriding the LookIn action handler,
     *   inheriting the default handling and adding our own message 
     */
    dobjFor(LookIn)
    {
        action()
        {
            /* show the default description */
            inherited();

            /* add a note that there's no ice, after a paragraph break */
            "<.p>It's been a long time since any ice was in there. ";
        }
    }
;

/*
 *   Define the player character.  The name of this object is not
 *   important, but note that it has to match up with the name we use in
 *   the main() routine to initialize the game, below.
 *   
 *   Note that we aren't required to define any vocabulary or description
 *   for this object, because the class Actor, defined in the library,
 *   automatically provides the appropriate definitions for an Actor when
 *   the Actor is serving as the player character.  Note also that we
 *   don't have to do anything special in this object definition to make
 *   the Actor the player character; any Actor can serve as the player
 *   character, and we'll establish this one as the PC in main(), below.  
 */
me: Actor
    /* the initial location is the entryway */
    location = frontGate
;

/*
 *   The "gameMain" object lets us set the initial player character and
 *   control the game's startup procedure.  Every game must define this
 *   object.  For convenience, we inherit from the library's GameMainDef
 *   class, which defines suitable defaults for most of this object's
 *   required methods and properties.  
 */
gameMain: GameMainDef
    /* the initial player character is 'me' */
    initialPlayerChar = me

    /* 
     *   Show our introductory message.  This is displayed just before the
     *   game starts.  Most games will want to show a prologue here,
     *   setting up the situation for the player, and show the title of the
     *   game.  
     */
    showIntro()
    {
        "You have been summoned to Darnley Park one winter's day to
        investigate the murder of Colonel Sebastian Darnley at some time
        the previous evening.
        <.p>
        The suspects are:
        <ul>
        <li>Sarah Darnley - the deceased's wife</li>
        <li>Milicent Darnlet - the deceased's daughter</li>
        <li>Arthur Coniston - fiance of Milicent</li>
        <li>Sir Redvers Slingsby - friend of the deceased</li>
        <li>Arnold Billingsgate - butler</li>
        <li>Mildred Goodbody - cook</li>
        <li>Norah Bagsby - housemaid</li>
        <li>Ronald Mellors - gamekeeper</li>
        </ul>
        You are free to search the house and grounds and to question the
        suspects. Examination of the scene and skillful interrogation will
        yield sufficient information to solver the mystery. And mystery it is!
        <.p>
        The body of Colonel Darnley was found in his study, the doors and
        window of which were all locked from the inside. The only keys were
        in the posession of the Colonel and his faithful butler. How could
        the sealed-room murder be comitted?
        <.p>";
    }

    /* 
     *   Show the "goodbye" message.  This is displayed on our way out,
     *   after the user quits the game.  You don't have to display anything
     *   here, but many games display something here to acknowledge that
     *   the player is ending the session.  
     */
    showGoodbye()
    {
        "<.p>Thanks for playing!\b";
    }
;

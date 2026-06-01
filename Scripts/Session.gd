extends Node2D

@export var promptGraphic: PackedScene

var vampireName = ""
var memories = []
var skills = []
var resources = []
var mortals = []
var immortals = []
var marks = []

var deceasedCharacters = []
var usedSkills = []
var lostResources = []

class Memory:
	var experiences = []

var evilResponse = ""
var evilChoice = null

var currentPrompt = 0
var prevPrompts = []
var noMatch = true
var endGame = false

@onready var sfxPlayer = get_node("SFX") as AudioStreamPlayer
@onready var musicPlayer = get_node("Music") as AudioStreamPlayer
@export var scribbleSFX: Array[AudioStream]
@export var pageSFX: AudioStream
@export var bgm: AudioStream

var SAVE_PATH = "user://TTYOV.cfg"

# candle shit
@export var min_alpha: float = .1
@export var max_alpha: float = .25
@export var baseSpeed: float = 8.0
var offsets = [.5, .0, 10.0, 3.0, 7.7]
var speeds = [.1, .5, .7, .4, .8]
@onready var candleStick = get_node("CanvasLayer/Candlestick")

@onready var textLabels = [get_node("CanvasLayer/Book/Character/Memories/Label"), get_node("CanvasLayer/Book/Expendables/Label")]

func _process(delta):
	
	var i = 0
	for c in candleStick.get_children():
		offsets[i] += delta * baseSpeed * speeds[i]
		var noise = (sin(offsets[i]) + 1.0) / 2.0 
		var target_alpha = lerp(min_alpha, max_alpha, noise)
		c.self_modulate.a = target_alpha
		i += 1
	
	# do scaling
	for t in textLabels:
		if(t.size.y > t.get_parent().size.y):
			var scalePercent = t.get_parent().size.y / t.size.y
			t.scale = Vector2(scalePercent, scalePercent)
			t.position = Vector2.ZERO



func _ready():
	
	var config = ConfigFile.new()
	var error = config.load(SAVE_PATH)
	
	if error == OK:
		var socketURL = config.get_value("Neuro", "WebsocketAddress", null)
		if(socketURL != null):
			OS.set_environment("NEURO_SDK_WS_URL", socketURL)
	else:
		var save = ConfigFile.new()
		config.set_value("Settings", "PlayMusic", true)
		config.set_value("Neuro", "WebsocketAddress", "ws://localhost:8000")
		config.save(SAVE_PATH)
		return
		
	var doMusic = config.get_value("Settings", "PlayMusic", true)
	if(!doMusic and is_instance_valid(musicPlayer)):
		musicPlayer.queue_free()

	
	
	# need to send them context on how responses should look for characters/memories/skills etc. Rules, basiclaly.
	Context.send("""Welcome to Thousand Year Old Vampire. In this solo journalling game, you'll play as a timeless being cursed with unlife, 
		as long as they slake their thirst on the blood of mortals. You'll answer prompts, manage resources and skills, and build a story from
		those interactions. Indulge your angsty thespian side, or add a dash of comedy if you fancy. The floor is yours, my leige...
		The next steps will guide you through character creation.""")
	
	await get_tree().create_timer(3).timeout
	
	var tween = get_tree().create_tween()
	tween.tween_property(get_node("CanvasLayer/Title"), "modulate", Color.TRANSPARENT, 2)
	await tween.finished
	
	get_node("CanvasLayer/Book/AnimationPlayer").play("Bookup")
	await get_tree().create_timer(1).timeout
	
	
	
	memories.append(Memory.new())
	memories.append(Memory.new())
	memories.append(Memory.new())
	memories.append(Memory.new())
	memories.append(Memory.new())
	
	var window = GetEvilText("Give your character a name:")
	await window.tree_exited
	vampireName = evilResponse ; evilResponse = ""
	
	window = GetEvilText("For their first memory, give your vampire an experience that encapsulates their existence before turning. For example: 'I am Agnes Merdew, a lady-in-waiting to the knightress Barbara-Ella. I dream of becoming a courtly warrior like her.' Experiences should be short and evocative, around 20~ words.")
	await window.tree_exited
	memories[0].experiences.append(evilResponse) ; evilResponse = ""
	
	# mortals
	
	window = GetEvilText("Create a mortal. This is someone your character knew during their life. Keep it short and flavourful, examples: 'Eulysse, the town hangman, my father. I fear his dark moods.' 'Tobias. A young hunter whose heart belongs to me.")
	await window.tree_exited
	mortals.append(evilResponse) ; evilResponse = ""
	
	window = GetEvilText("Create another mortal.")
	await window.tree_exited
	mortals.append(evilResponse) ; evilResponse = ""
	
	window = GetEvilText("One last mortal:")
	await window.tree_exited
	mortals.append(evilResponse) ; evilResponse = ""
	
	# skills
	
	window = GetEvilText("Now let's give your vampire a skill that they would have picked up in their regular life. Examples: 'Gossip', 'Armour maintainance', 'Courtly manners'")
	await window.tree_exited
	skills.append(evilResponse) ; evilResponse = ""
	
	window = GetEvilText("Give them another skill.")
	await window.tree_exited
	skills.append(evilResponse) ; evilResponse = ""
	
	window = GetEvilText("One last skill:")
	await window.tree_exited
	skills.append(evilResponse) ; evilResponse = ""
	
	# resources
	
	window = GetEvilText("Your vampire would have obtained some resources while they were still mortal, for example 'The hidden dugout' or 'Ceremonial dress'. Let's write one down:")
	await window.tree_exited
	resources.append(evilResponse) ; evilResponse = ""
	
	window = GetEvilText("Let's add another resource.")
	await window.tree_exited
	resources.append(evilResponse) ; evilResponse = ""
	
	window = GetEvilText("One last resource:")
	await window.tree_exited
	resources.append(evilResponse) ; evilResponse = ""
	
	# final experiences
	
	var rTraits = RandomTraits(2)
	window = GetEvilText("Round out your memories by creating some more experiences. Let's make the first one centered on a combination of '" + rTraits[0] + "' and '" + rTraits[1] + "'")
	await window.tree_exited
	memories[1].experiences.append(evilResponse) ; evilResponse = ""
	
	rTraits = RandomTraits(2)
	window = GetEvilText("Let's make the second experience about '" + rTraits[0] + "' and '" + rTraits[1] + "'")
	await window.tree_exited
	memories[2].experiences.append(evilResponse) ; evilResponse = ""
	
	rTraits = RandomTraits(2)
	window = GetEvilText("And the final experience should focus on a combination of '" + rTraits[0] + "' and '" + rTraits[1] + "'")
	await window.tree_exited
	memories[3].experiences.append(evilResponse) ; evilResponse = ""
	
	# wrapping up
	
	window = GetEvilText("Let's make an immortal character - the creature that gifted (or cursed) your vampire with unlife.")
	await window.tree_exited
	immortals.append(evilResponse) ; evilResponse = ""
	
	window = GetEvilText("How does the curse physically show? Give your character a Mark.")
	await window.tree_exited
	marks.append(evilResponse) ; evilResponse = ""
	
	window = GetEvilText("Lastly, note down the experience that started this all - the moment you became a vampire.")
	await window.tree_exited
	memories[4].experiences.append(evilResponse) ; evilResponse = ""
	
	
	UpdateGraphics()
	Context.send("That's character creation wrapped up! If you want to, you can maybe draw your character before we start their journey.")
	var actionWindow := ActionWindow.new(self)
	actionWindow.set_force(0, "Send START when you're ready to begin.", "", false, ActionsForce.Priority.LOW)
	actionWindow.add_action(NeuroText.new(self, actionWindow)) ; actionWindow.register()
	await actionWindow.tree_exited
	
	NextPrompt()


func RandomTraits(amount=1):
	var t = []
	var prevRolls = [-1]
	for i in amount:
		var roll = -1
		while(prevRolls.has(roll)):
			roll = randi_range(1, skills.size() + resources.size() + mortals.size() + immortals.size()) -1
		prevRolls.append(roll)
		
		if(roll < skills.size()): t.append(skills[roll])
		else:
			roll -= skills.size()
			if(roll < resources.size()): t.append(resources[roll])
			else:
				roll -= resources.size()
				if(roll < mortals.size()): t.append(mortals[roll])
				else:
					roll -= mortals.size()
					t.append(immortals[roll])
	return t



func NextPrompt():
	
	Context.send("A new event unfolds...", true)
	
	sfxPlayer.stream = pageSFX
	sfxPlayer.play()
	
	var roll = max(currentPrompt + randi_range(1, 10) - randi_range(1, 6), 1)
	currentPrompt = roll
	var window = null
	noMatch = true
	var recordExperience = true
	
	while true:
		if(roll > 80): 
			endGame = true ; return
		
		if(prevPrompts.has(str(roll) + "A")):
			if(prevPrompts.has(str(roll) + "B")):
				if(prevPrompts.has(str(roll) + "C")):
					roll += 1
					currentPrompt += 1
				else: roll = str(roll) + "C" ; break
			else: roll = str(roll) + "B" ; break
		else: roll = str(roll) + "A" ; break
	
	prevPrompts.append(roll)
	print("----- New prompt: " + roll + "-----")
	
	
	match roll:
		"1A": 
			DisplayPrompt("In a frenzy of hunger, you kill someone close to you. Gain the skill 'Bloodthirsty'.")
			skills.append("Bloodthirsty")
			if(mortals.size() > 0):
				window = GetEvilChoice("Choose the mortal that meets this fate:", mortals)
				await window.tree_exited
				deceasedCharacters.append(evilChoice)
				mortals.erase(evilChoice) ; evilChoice = null
			else:
				window = GetEvilText("Create the mortal that met this fate:")
				await window.tree_exited
				deceasedCharacters.append(evilResponse) ; evilResponse = ""
		"1B":
			DisplayPrompt("In a moment of panic, you murder someone close to you. They join you in unlife. You gain the Ashamed skill.")
			skills.append("Ashamed")
			if(mortals.size() > 0):
				window = GetEvilChoice("Choose the beloved mortal that meets this fate:", mortals)
				await window.tree_exited
				deceasedCharacters.append(evilChoice)
				mortals.erase(evilChoice) ; evilChoice = null
			else:
				window = GetEvilText("Create the beloved mortal that met this fate:")
				await window.tree_exited
				deceasedCharacters.append(evilResponse) ; evilResponse = ""
		"1C":
			DisplayPrompt("A powerful immortal ensnares you in their ancient will. How do you eventually escape their servitude? You gain the skill 'Humans are cattle'")
			skills.append("Humans are cattle")
			window = GetEvilText("Create this immortal character:")
			await window.tree_exited
			immortals.append(evilResponse) ; evilResponse = ""
			
			window = GetEvilChoice("How do you eventually escape their servitude?", skills)
			await window.tree_exited
			usedSkills.append(evilChoice) ; skills.erase(evilChoice) ; evilChoice = null
		
		"2A":
			DisplayPrompt("You retreat from society, overcome by horror at your nature. Where do you hide from the humans?")
			window = GetEvilText("Create a stationary resource that shelters you.")
			await window.tree_exited
			resources.append(evilResponse) ; evilResponse = ""
			
		"2B":
			DisplayPrompt("You start to become one with your residence, an extension of it even as it falls to disrepair around you. How do you come to appreciate the place anew?")
			window = GetEvilText("Create a skill based on a memory.")
			await window.tree_exited
			skills.append(evilResponse) ; evilResponse = ""
		"2C":
			DisplayPrompt("Mortals raze your dwelling space to the ground. How do you survive? What terrible vengeance do you reign upon them? You gain the skill 'Vile acts'.")
			skills.append("Vile acts")
			window = GetEvilChoice("Degrade a resource into ruins:", resources)
			await window.tree_exited
			resources.erase(evilChoice) ; evilChoice = null
		
		"3A":
			DisplayPrompt("A kind mortal takes pity on you and works to help your plight.")
			if(mortals.size() == 0):
				window = GetEvilText("Create the mortal in question:")
				await window.tree_exited
				mortals.append(evilResponse) ; evilResponse = ""
			
			window = GetEvilText("Create a resource that represents their assistance.")
			await window.tree_exited
			resources.append(evilResponse) ; evilResponse = ""
		"3B":
			DisplayPrompt("You manipulate the helpful mortal into committing atrocious acts on your behalf. When they falter, how do you respond? Gain the skill 'Humans are tools'")
			skills.append("Humans are tools")
		"3C": 
			DisplayPrompt("At the end of the helpful mortal's life, you convert them into a husk, a mere object for you to feed of. What were the last words they spoke to you? Change that character to a resource.")
			if(mortals.size() == 0):
				window = GetEvilText("Create the mortal in question:")
				await window.tree_exited
				resources.append(evilResponse) ; evilResponse = ""
			else:
				window = GetEvilChoice("Select the mortal in question:", mortals)
				await window.tree_exited
				resources.append(evilChoice) ; mortals.erase(evilChoice) ; evilChoice = null
			
			window = GetEvilChoice("Use a skill:", skills)
			await window.tree_exited
			usedSkills.append(evilChoice) ; skills.erase(evilChoice) ; evilChoice = null
		
		"4A":
			DisplayPrompt("You are exposed, and flee to a neighboring region. \nA mortal flees with you. What new name do you adopt among these strangers?")
			window = GetEvilChoice("Lose a stationary resource.", resources)
			await window.tree_exited
			resources.erase(evilChoice) ; evilChoice = null
			
			window = GetEvilChoice("Use a skill:", skills)
			await window.tree_exited
			usedSkills.append(evilChoice) ; skills.erase(evilChoice) ; evilChoice = null
		"4B":
			DisplayPrompt("You are adopted into a strange cult who take you in despite (or because of) your outlander origin.\nYou gain the resource 'The secret cabal'. How did they find you? What vile initiation ceremony do you undergo? Do they know what you are?")
			resources.append("The secret cabal")
			window = GetEvilChoice("Use a skill:", skills)
			await window.tree_exited
			usedSkills.append(evilChoice) ; skills.erase(evilChoice) ; evilChoice = null
			
		"4C":
			DisplayPrompt("The secret cabal has performed an evil rite while you were absent, converting a mortal into a powerful, nightmarish immportal thing. What otherworldly goal do they start to pursue? How do this affect your perspective of the cabal?")
			if(mortals.size() == 0):
				window = GetEvilText("Create the immortal in question:")
				await window.tree_exited
				immortals.append(evilResponse) ; evilResponse = ""
			else:
				window = GetEvilChoice("Select the mortal that was converted:", mortals)
				await window.tree_exited
				immortals.append(evilChoice) ; mortals.erase(evilChoice) ; evilChoice = null
				
				window = GetEvilText("Update their entry to match this terrifying new form.")
				await window.tree_exited
				immortals[immortals.size()-1] = evilResponse ; evilResponse = ""
		
		"5A":
			DisplayPrompt("Someone dear to you threatens to expose you, and in your fear you murder them.")
			var characters = mortals.duplicate()
			characters.append_array(immortals.duplicate())
			if(characters.size() > 0):
				window = GetEvilChoice("Choose the character that must die:", characters)
				await window.tree_exited
				deceasedCharacters.append(evilChoice)
				if(mortals.has(evilChoice)): mortals.erase(evilChoice)
				else: immortals.erase(evilChoice)
				evilResponse = ""
			else:
				window = GetEvilText("Create the beloved mortal you have betrayed:")
				await window.tree_exited
				mortals.append(evilResponse) ; evilResponse = ""
			
			window = GetEvilChoice("How did you kill them?", skills)
			await window.tree_exited
			usedSkills.append(evilChoice) ; skills.erase(evilChoice) ; evilChoice = null
		"5B":
			DisplayPrompt("One of your past victims returns to you in your dreams, seeking revenge. Do you beg their pardon, or rage against their intrusion? What new supernatural mark do you recieve from the encounter?")
			window = GetEvilText("Choose the mark:")
			await window.tree_exited
			marks.append(evilResponse) ; evilResponse = ""
		"5C":
			DisplayPrompt("A lingering regret or love stirs you to action. What foolish quest do you shoulder in an attempt to atone for old sins? What justice do you fail to bring, and how does it go terribly, terribly wrong?")
			
			window = GetEvilChoice("Lose a resource.", resources)
			await window.tree_exited
			resources.erase(evilChoice) ; evilChoice = null
			
			window = GetEvilChoice("Use a skill.", skills)
			await window.tree_exited
			usedSkills.append(evilChoice) ; skills.erase(evilChoice) ; evilChoice = null
		
		"6A":
			DisplayPrompt("A mortal character offers their service. Do you accept? What do you belive their motives are?")
			
			window = GetEvilText("Create the mortal servant.")
			await window.tree_exited
			mortals.append(evilResponse) ; evilResponse = ""
		"6B":
			DisplayPrompt("Despite your growing suspicion, a mortal betrays you in an unforseen manner. Why did they do this? Why do you give them one last chance at redemption? Lose a resource.")
			window = GetEvilChoice("Lose a resource:", resources)
			await window.tree_exited
			resources.erase(evilChoice) ; evilChoice = null
		"6C":
			DisplayPrompt("A mortal gives their life to save you. Use a skill, and gain a skill based around hope or love.")
			window = GetEvilChoice("Use a skill.", skills)
			await window.tree_exited
			usedSkills.append(evilChoice) ; skills.erase(evilChoice) ; evilChoice = null
		
		"7A":
			DisplayPrompt("Your mark manifests your power, growing more obvious and supernatural. Create a skill reflecting this.")
			window = GetEvilText("Add the skill")
			await window.tree_exited
			skills.append(evilResponse) ; evilResponse = ""
		"7B":
			DisplayPrompt("Someone calls you a demon, citing a mark you bear that previously slipped your notice. What irksome inconvenience has this public accusal caused you?")
			
			window = GetEvilText("Create the mark.")
			await window.tree_exited
			marks.append(evilResponse) ; evilResponse = ""
			
			window = GetEvilText("Create the suspicious mortal.")
			await window.tree_exited
			mortals.append(evilResponse) ; evilResponse = ""
		"7C":
			DisplayPrompt("You grit your teeth and perform the grisly process of removing a mark. Is it successful? Who do you curse through the pain?")
			
			var options = marks.duplicate()
			options.append("I'd prefer to replace a mark with something worse")
			window = GetEvilChoice("Choose a mark", options)
			await window.tree_exited
			if(evilChoice != "I'd prefer to replace a mark with something worse"):
				marks.erase(evilChoice) ; evilChoice = null
			else:
				window = GetEvilChoice("Choose a mark to replace:", marks)
				await window.tree_exited
				marks.erase(evilChoice) ; evilChoice = null
				
				window = GetEvilText("Create the new mark:")
				await window.tree_exited
				marks.append(evilResponse) ; evilResponse = ""
		"8A":
			DisplayPrompt("Another supernatural entity reveals themselves to you. What clandestine manner do they use to make contact? What have they taken from you?")
			window = GetEvilText("Create the immortal:")
			await window.tree_exited
			immortals.append(evilResponse) ; evilResponse = ""
			
			window = GetEvilChoice("Lose a resource:", resources)
			await window.tree_exited
			resources.erase(evilChoice) ; evilChoice = null
		"8B":
			DisplayPrompt("An immortal character falls for a trap you set. What secret do they reveal in captivity? How do they buy their freedom?")
			
			var options = GetMemories()
			window = GetEvilChoice("Choose a memory to convert into a skill:", options)
			await window.tree_exited
			memories.remove_at(options.find(evilChoice)) ; evilChoice = null
			memories.append(Memory.new())
			
			window = GetEvilText("Create the skill derived from that memory:")
			await window.tree_exited
			skills.append(evilResponse) ; evilResponse = ""
			
			window = GetEvilText("Gain a mysterious resource from the immortal:")
			await window.tree_exited
			resources.append(evilResponse) ; evilResponse = ""
		"8C":
			DisplayPrompt("Someone you've wronged seeks revenge through a powerful alliance. Add an enemy immortal who leads the crusade against you. How do you evade their justice? Use a skill, and gain the skill 'Time to leave'. What do you leave behind when you flee this land?")
			window = GetEvilText("Create the immortal:")
			await window.tree_exited
			immortals.append(evilResponse) ; evilResponse = ""
			
			window = GetEvilChoice("Use a skill:", skills)
			await window.tree_exited
			usedSkills.append(evilChoice) ; skills.erase(evilChoice) ; evilChoice = null
			skills.append("Time to leave")
			
			window = GetEvilChoice("Choose what you leave behind:", resources)
			await window.tree_exited
			resources.erase(evilChoice) ; evilChoice = null
		
		"9A":
			DisplayPrompt("You find a way to reliably slake your bloodthirst. What becomes of the corpses? Gain a skill.")
			window = GetEvilText("Gain a skill:")
			await window.tree_exited
			skills.append(evilResponse) ; evilResponse = ""
		"9B":
			DisplayPrompt("Blood is not the only thing you drain from your victims - their bank accounts suffer as well. How are you extracting both so cleanly? How does it nearly all go wrong?")
			
			window = GetEvilChoice("Use a skill:", skills)
			await window.tree_exited
			usedSkills.append(evilChoice) ; skills.erase(evilChoice) ; evilChoice = null
			
			window = GetEvilText("Gain a resource.")
			await window.tree_exited
			resources.append(evilResponse) ; evilResponse = ""
		"9C":
			DisplayPrompt("Your system of acquiring blood and money grows beyond you, as others take the reigns and revolutionize it. Do you beg for a place in this new hierarchy, or strike out on your own again?")
			
			var options = ["Crawl back", "Strike out"]
			window = GetEvilChoice("Choose:", options)
			await window.tree_exited
			if(evilResponse == "Crawl back"): skills.append("Belly on the ground") ; evilChoice = null
			else:
				evilChoice = null
				window = GetEvilChoice("Use a skill:", skills)
				await window.tree_exited
				usedSkills.append(evilChoice) ; skills.erase(evilChoice) ; evilChoice = null
				
				window = GetEvilChoice("Use another skill:", skills)
				await window.tree_exited
				usedSkills.append(evilChoice) ; skills.erase(evilChoice) ; evilChoice = null
				
				window = GetEvilText("Gain a resource.")
				await window.tree_exited
				resources.append(evilResponse) ; evilResponse = ""
		"10A":
			DisplayPrompt("The wheel of time turns, and ages come and pass, leaving memories that eventually die alonogside those who made them. Remove a memory and all mortals.")
			var options = GetMemories()
			window = GetEvilChoice("Choose a memory to erase:", options)
			await window.tree_exited
			memories.remove_at(options.find(evilChoice)) ; evilChoice = null
			memories.append(Memory.new())
			deceasedCharacters.append_array(mortals)
			mortals.clear()
		"10B":
			DisplayPrompt("An object of power finds its way into your hands, giving you the power to rewrite reality.\nGain the item as a resource. If you still hold this resource when the game ends, you can rewrite the ending to be as you wish - but if an immortal takes a resource from you, it always chooses the item. first.")
			
			window = GetEvilText("Create the resource:")
			await window.tree_exited
			resources.append(evilResponse) ; evilResponse = ""
			
			window = GetEvilText("Who did you acquire it from? Create a mortal.")
			await window.tree_exited
			mortals.append(evilResponse) ; evilResponse = ""
		"10C":
			DisplayPrompt("Thieves attempt to seize your artifact, and it breaks in the chaos. Reality splits, light vs. dark, angels against demons. The world enters a cosmic war with powers on both sides - powers that take an interest in you.")
			var options = ["Resource", "Character"]
			window = GetEvilChoice("Create the manifestation of a supernatural conflict that fits your story up to this point. Is it more of a character, or a resource?", options)
			await window.tree_exited
			var sett = resources
			if(evilChoice == "Character"):
				sett = immortals
			evilChoice = null
			
			window = GetEvilText("Create the manifestation:")
			await window.tree_exited
			sett.append(evilResponse) ; evilResponse = ""
			
			window = GetEvilText("Create an immortal on one side of the conflict.")
			await window.tree_exited
			immortals.append(evilResponse) ; evilResponse = ""
			
			window = GetEvilText("Create another immortal on one opposing side.")
			await window.tree_exited
			immortals.append(evilResponse) ; evilResponse = ""
		
		"11A":
			DisplayPrompt("How do you distract yourself from the ravenous hunger for blood?")
			window = GetEvilChoice("Use a skill:", skills)
			await window.tree_exited
			skills.erase(evilChoice) ; evilChoice = null
		"11B":
			DisplayPrompt("You discover a means of meditation or other control method that can curtail your baser instincts. Lose a violent memory, gain the skill 'I control the beast', and reqrite another skill.")
			skills.append("I control the beast")
			var options = GetMemories()
			window = GetEvilChoice("Choose a violent memory:", options)
			await window.tree_exited
			memories.remove_at(options.find(evilChoice)) ; evilChoice = null
			memories.append(Memory.new())
			
			window = GetEvilChoice("Choose a skill to rewrite:", skills)
			await window.tree_exited
			skills.erase(evilChoice) ; evilChoice = null
			
			window = GetEvilText("Rewrite it as:")
			await window.tree_exited
			skills.append(evilResponse) ; evilResponse = ""
		"11C":
			DisplayPrompt("You lose control. You bathe in a sea of death and red. The thirst refuses to abate until you lose yourself to it. Replace a cherished memory with the overbearing hunger. Create a skill that mocks your former attempts to remain in command.")
			var options = GetMemories()
			window = GetEvilChoice("Choose a cherished memory:", options)
			await window.tree_exited
			memories.remove_at(options.find(evilChoice)) ; evilChoice = null
			
			window = GetEvilText("Add the first experience giving in to the hunger:")
			await window.tree_exited
			memories.append(Memory.new())
			memories.back().experiences.append(evilResponse); evilResponse = ""
		
		"12A":
			DisplayPrompt("A societal change reduces your ability to blend in. What steps must you take to keep your nature a secret? Use a skill, create a skill, and create a mortal who helps you out.")
			window = GetEvilChoice("Use a skill:", skills)
			await window.tree_exited
			skills.erase(evilChoice) ; evilChoice = null
			
			window = GetEvilText("Gain a skill:")
			await window.tree_exited
			skills.append(evilResponse) ; evilResponse = ""
			
			window = GetEvilText("Create the helpful mortal:")
			await window.tree_exited
			mortals.append(evilResponse) ; evilResponse = ""
		"12B":
			DisplayPrompt("Your extended lifespan lets you play with political leaders as if they were pawns. How do you manipulate them to your ends? Create a resource.")
			window = GetEvilText("Add the resource:")
			await window.tree_exited
			resources.append(evilResponse) ; evilResponse = ""
		"12C":
			DisplayPrompt("You are bested by a mere mortal, who reveals themselves to be ten steps ahead of you. What ruthless plan do they enact to ensnare you?")
			window = GetEvilText("Create the wicked mortal:")
			await window.tree_exited
			mortals.append(evilResponse) ; evilResponse = ""
		
		"13A":
			DisplayPrompt("You acquire the dedicated service of an entire house, bound to you through the ages. Choose the family of a mortal, living or dead - In what awkward manner do they display their devotion?")
			window = GetEvilChoice("Lose a resource:", resources)
			await window.tree_exited
			resources.erase(evilChoice) ; evilChoice = null
			
			var options = mortals.duplicate()
			options.append_array(deceasedCharacters.duplicate())
			window = GetEvilChoice("Which mortal is the family desceneded from?", options)
			await window.tree_exited
			evilChoice = null
			skills.append("Servitors of the lineage")
		"13B":
			DisplayPrompt("Your servants are legion, rich with equal zeal and incompetence. Create a skill based on a memory - this is how you keep them in line.")
			var options = GetMemories()
			window = GetEvilChoice("Choose a memory", options)
			await window.tree_exited
			evilChoice = null
			
			window = GetEvilText("Create a skill based on that memory:")
			await window.tree_exited
			skills.append(evilResponse) ; evilResponse = ""
		"13C":
			DisplayPrompt("You are gifted something annoying, dangerous, or otherwise undesirable. Create a resource you would rather not have.")
			window = GetEvilText("Create the resource:")
			await window.tree_exited
			resources.append(evilResponse) ; evilResponse = ""
		
		"14A":
			DisplayPrompt("An enemy reclaims something you lost long ago, using it to turn your few allies against you. Do you try to reclaim the object, or weather the assault? Who must die as a consequence? Where do you retreat to lick your wounds?")
			var oldResource
			if(lostResources.size() != 0):
				window = GetEvilChoice("Which lost resource is used against you?", lostResources)
				await window.tree_exited
				oldResource = evilChoice ; evilChoice = null
			
			var options = ["Use three skills to reclaim the resource", "Use one skill to barely survive"]
			window = GetEvilChoice("Make a choice:", options)
			await window.tree_exited
			if(evilChoice == "Use one skill to barely survive"):
				window = GetEvilChoice("Use a skill:", skills)
				await window.tree_exited
				skills.erase(evilChoice) ; evilChoice = null
			else:
				window = GetEvilChoice("Use the first skill:", skills)
				await window.tree_exited
				skills.erase(evilChoice) ; evilChoice = null
				
				window = GetEvilChoice("Use the second skill:", skills)
				await window.tree_exited
				skills.erase(evilChoice) ; evilChoice = null
				
				window = GetEvilChoice("Use the final skill:", skills)
				await window.tree_exited
				skills.erase(evilChoice) ; evilChoice = null
				
				if(oldResource != null):
					resources.append(oldResource)
				else:
					window = GetEvilText("Create the resource:")
					await window.tree_exited
					resources.append(evilResponse) ; evilResponse = ""
				
			evilChoice = null
		"14B":
			DisplayPrompt("The world has changed greatly since when you were first cursed. How must you compromise to fit into this new paradigm?")
			
			window = GetEvilText("Create an appropriate contemporary skill based on your most recent memory.")
			await window.tree_exited
			skills.append(evilResponse) ; evilResponse = ""
			
			window = GetEvilText("What new name have you recently adopted?")
			await window.tree_exited
			vampireName = evilResponse ; evilResponse = ""
		"14C":
			DisplayPrompt("Your influence expands to rule over the mortals. How do you keep them downtrodden beneath your iron boot? Gain a resource obtained through the spoils of war.")
			window = GetEvilText("Create the resource:")
			await window.tree_exited
			resources.append(evilResponse) ; evilResponse = ""
		
		"15A":
			DisplayPrompt("You venture into a mysterious place, and cross paths with a new immortal. What did you seek in this place? Why do they prevent you from obtaining it?")
			window = GetEvilText("Create the immortal:")
			await window.tree_exited
			immortals.append(evilResponse) ; evilResponse = ""
		"15B":
			DisplayPrompt("You discover there is more to an immortal than meets the eye. What lie have they led you to believe? What new advantage does this revelation offer?")
			var options = ["Use a skill", "Lose a resource", "Lose a memory"]
			window = GetEvilChoice("Make a choice:", options)
			await window.tree_exited
			if(evilChoice == "Use a skill"):
				evilChoice = null
				window = GetEvilChoice("Choose the skill to use:", skills)
				await window.tree_exited
				skills.erase(evilChoice)
			elif(evilChoice == "Lose a resource"):
				window = GetEvilChoice("Choose the resource to use:", resources)
				await window.tree_exited
				resources.erase(evilChoice)
				evilChoice = null
			else:
				options = GetMemories()
				window = GetEvilChoice("Choose the memory to lose:", options)
				await window.tree_exited
				memories.remove_at(options.find(evilChoice)) ; evilChoice = null
				memories.append(Memory.new())
			evilChoice = null
			
			options = ["Gain a skill", "Gain a resource"]
			window = GetEvilChoice("Make a choice:", options)
			await window.tree_exited
			
			if(evilChoice == "Gain a skill"):
				window = GetEvilText("Create the skill:")
				await window.tree_exited
				skills.append(evilResponse)
			else:
				window = GetEvilText("Create the resource:")
				await window.tree_exited
				resources.append(evilResponse)
			
			evilResponse = ""
			evilChoice = null
		"15C":
			DisplayPrompt("How has the machinations of immortals impacted the lives of regular folk? WHat has your schemeing cost you? Gain a resource, skill, or mark.")
			window = GetEvilChoice("Lose a resource:", resources)
			await window.tree_exited
			resources.erase(evilChoice) ; evilChoice = null
			
			var options = ["Gain a resource", "Gain a skill", "Gain a mark"]
			window = GetEvilChoice("Make a choice:", options)
			await window.tree_exited
			if(evilChoice == "Gain a resource"):
				window = GetEvilText("Create the resource:")
				await window.tree_exited
				resources.append(evilResponse)
			elif(evilChoice == "Gain a skill"):
				window = GetEvilText("Create the skill:")
				await window.tree_exited
				skills.append(evilResponse)
			else:
				window = GetEvilText("Create the mark:")
				await window.tree_exited
				marks.append(evilResponse)
			evilResponse = ""
		
		"16A": 
			DisplayPrompt("A dangerous alliance of mortals has formed with the express purpose of hunting you down. How do you manage to overcome their ploys? Create a powerful mortal related to a previously used skill.")
			window = GetEvilText("Create the hunter mortal:")
			await window.tree_exited
			mortals.append(evilResponse)
			
			window = GetEvilChoice("Use a skill:", skills)
			await window.tree_exited
			skills.erase(evilChoice) ; evilChoice = null
		"16B":
			DisplayPrompt("THe hunters prove to be a recurring thorn in your side, always appearing one step ahead of you. Create a mark that you extract from one of their members. You are forced to flee to a desolate wilderness - What must you leave behind? How do you survive here?")
			window = GetEvilText("Create the mark:")
			await window.tree_exited
			marks.append(evilResponse) ; evilResponse = ""
			
			window = GetEvilChoice("Lose a stationary resource:", resources)
			await window.tree_exited
			resources.erase(evilChoice) ; evilChoice = null
			
			window = GetEvilText("Learn a new skill:")
			await window.tree_exited
			skills.append(evilResponse) ; evilResponse = ""
		"16C":
			DisplayPrompt("An age passes, and you return to a place you were once villified to bring your wrath down upon those now too old to pose a thrreat. Create a mortal who was naieve and innocent until you showed them true fear.")
			window = GetEvilText("Create the mortal:")
			await window.tree_exited
			mortals.append(evilResponse) ; evilResponse = ""
		
		"17A":
			DisplayPrompt("You draw blood, but for some other reason than to slake your thirst. Use a skill and remove a mortal character if appropriate.")
			window = GetEvilChoice("Use a skill:", skills)
			await window.tree_exited
			skills.erase(evilChoice) ; evilChoice = null
			
			var options = mortals.duplicate()
			options.append("Do not remove a mortal")
			window = GetEvilChoice("Remove a mortal:", options)
			await window.tree_exited
			if(evilResponse != "Do not remove a mortal"):
				skills.erase(evilChoice)
			evilChoice = null
		"17B":
			DisplayPrompt("Lawkeepers pursue you for a past crime. Use a skill and resource. Who do you confide in? Choose an enemy character to become a friend (or vice-versa).")
			
			window = GetEvilChoice("Use a skill:", skills)
			await window.tree_exited
			skills.erase(evilChoice) ; evilChoice = null
			
			window = GetEvilChoice("Use a resource:", resources)
			await window.tree_exited
			resources.erase(evilChoice) ; evilChoice = null
			
			if(mortals.size() == 0 or immortals.size() == 0):
				window = GetEvilText("Create a mortal character you fall in love with:")
				await window.tree_exited
				mortals.append(evilResponse) ; evilResponse = ""
		"17C":
			DisplayPrompt("A beloved character stands in your way. What terrible mark do they leave upon you in the clash? Use a skill or resource to defeat them, or gain a mark and flee this blighted land.")
			var options = ["Kill them", "Flee"]
			window = GetEvilChoice("Make a choice:", options)
			await window.tree_exited
			var kill = true
			if(evilChoice == "Flee"):
				kill = false
			evilChoice = null
			
			if(kill):
				options = ["Use a skill", "Lose a resource"]
				window = GetEvilChoice("Make a choice:", options)
				await window.tree_exited
				if(evilChoice == "Use a skill"):
					evilChoice = null
					window = GetEvilChoice("Choose the skill to use:", skills)
					await window.tree_exited
					skills.erase(evilChoice)
				elif(evilChoice == "Lose a resource"):
					window = GetEvilChoice("Choose the resource to use:", resources)
					await window.tree_exited
					resources.erase(evilChoice)
					evilChoice = null
			else:
				window = GetEvilText("Gain a mark:")
				await window.tree_exited
				marks.append(evilResponse) ; evilResponse = ""
			
			if(mortals.size() == 0 or immortals.size() == 0):
				window = GetEvilText("Create the beloved character:")
				await window.tree_exited
				var newCharName = evilResponse ; evilResponse = ""
				
				if(kill): deceasedCharacters.append(newCharName)
				else: 
					options = ["Mortal", "Immortal"]
					window = GetEvilChoice("Choose this character's nature:", options)
					await window.tree_exited
					if(evilChoice == "Immortal"): immortals.append(newCharName)
					else: mortals.append(newCharName)
					evilChoice = null
			else:
				if(kill):
					options = immortals.duplicate()
					options.append_array(mortals.duplicate())
					window = GetEvilChoice("Choose a beloved character:", options)
					await window.tree_exited
					
					deceasedCharacters.append(evilChoice) 
					if(mortals.has(evilChoice)): mortals.erase(evilChoice)
					else: immortals.erase(evilChoice)
					evilChoice = null
		"18A":
			DisplayPrompt("A profound sense of duty or a crushing threat forces you to swear an oath that strains the limits of your endurance. Who demanded this pact, and what ruin awaits you if you falter?")
			resources.append("The Vow I Keep")
			window = GetEvilChoice("Use a skill to bind your oath:", skills)
			await window.tree_exited
			usedSkills.append(evilChoice); skills.erase(evilChoice); evilChoice = null
		"18B":
			DisplayPrompt("You discover you are not at the top of the food chain. A terrifying, ancient entity hunts your kind for sustenance - yet, it treats you with a bizarre, almost maternal benevolence.")
			window = GetEvilText("Create the enigmatic apex immortal:")
			await window.tree_exited
			immortals.append(evilResponse); evilResponse = ""
		"18C":
			DisplayPrompt("Coarse, common blood no longer satisfies you; your predatory desires have warped into something obsessively specific and dangerous. What impossible restrictions now dictate how, or from whom, you must feed?")
			
			# Penalizes the player's flexibility by forcing them to use an existing skill or lose a resource
			var options = ["Sacrifice a skill to adapt", "Lose a resource to secure your niche"]
			window = GetEvilChoice("How do you manage this extreme hunger?", options)
			await window.tree_exited
			
			if evilChoice == "Sacrifice a skill to adapt":
				window = GetEvilChoice("Choose a skill to lose:", skills)
				await window.tree_exited
				skills.erase(evilChoice); evilChoice = null
			else:
				window = GetEvilChoice("Choose a resource to lose:", resources)
				await window.tree_exited
				resources.erase(evilChoice); evilChoice = null
		"19A":
			DisplayPrompt("A specific breed of crawling or flying pests has taken up residence inside your crypt. Are they a wretched nuisance, or have you found a macabre way to put these creatures to use?")
			
			window = GetEvilText("Create a Skill based on how you coexist with them:")
			await window.tree_exited
			skills.append(evilResponse); evilResponse = ""
		"19B":
			DisplayPrompt("A single date on the mortal calendar holds an undeniable significance to your undead mind. What memory haunts you of this night, and what lonely ritual do you perform to mark its passing?")
			
			var options = GetMemories()
			window = GetEvilChoice("Select the Memory that ties you to this date:", options)
			await window.tree_exited
			evilChoice = null
		"19C":
			DisplayPrompt("The pests in your sanctuary thrive on something you leave behind, and worse things have crawled out of the woodwork to hunt them in the dark. You exist at the center of a tiny, foul ecosystem. Create a Resource born from this grotesque environment.")
			
			window = GetEvilText("Create the resource:")
			await window.tree_exited
			resources.append(evilResponse); evilResponse = ""
		
		"20A":
			DisplayPrompt("A malignant pathogen has mutated within your stagnant veins, turning your bite into the epicenter of a new epidemic. What are the horrifying symptoms of this disease?")
			
			window = GetEvilText("Gain a mark")
			await window.tree_exited
			marks.append(evilResponse); evilResponse = ""
			
			if mortals.size() > 0:
				window = GetEvilChoice("Which of your existing contacts have you already infected?", mortals)
				await window.tree_exited
				evilChoice = null
		"20B":
			DisplayPrompt("Wherever you walk, the contagion follows. How does this catch the eye of the authorities? How do you evade their inquisition? Who seeks to weaponize, exploit, or purge the infected?")
			
			window = GetEvilChoice("Use a skill:", skills)
			await window.tree_exited
			usedSkills.append(evilChoice); skills.erase(evilChoice); evilChoice = null
			
			window = GetEvilText("Create a mortal character searching for a cure or studying the disease:")
			await window.tree_exited
			mortals.append(evilResponse); evilResponse = ""
			
			window = GetEvilText("Create a mortal trying to exploit the infection:")
			await window.tree_exited
			mortals.append(evilResponse); evilResponse = ""
		"20C":
			DisplayPrompt("Your infected victims mutate into something altogether different, permanently altering the geopolitical landscape. How does this force you to change your methods of survival? Who has benefited from this disaster?")
			
			window = GetEvilChoice("Lose a Resource swallowed up by the global collapse:", resources)
			await window.tree_exited
			resources.erase(evilChoice); evilChoice = null
			
			window = GetEvilText("Gain a Skill that helps you exploit or navigate this drastically changed world:")
			await window.tree_exited
			skills.append(evilResponse); evilResponse = ""
			
			window = GetEvilText("Create a mortal character who rises to immense power or political prominence amidst the chaos:")
			await window.tree_exited
			mortals.append(evilResponse); evilResponse = ""
		
		"21A":
			DisplayPrompt("An overwhelming fixation drives you beneath the dirt. You begin to excavate, tunneling deeper into the cold crust of the earth away from the starlight. What manic urge drives you downward into the dark?")
			
			window = GetEvilText("Create a Skill:")
			await window.tree_exited
			skills.append(evilResponse); evilResponse = ""
		"21B":
			DisplayPrompt("Deep beneath the soil, you encounter another resident of the underworld. What impossible subterranean wonders or ancient secrets do they reveal to you?")
			
			window = GetEvilText("Create the guide:")
			await window.tree_exited
			immortals.append(evilResponse); evilResponse = ""
		"21C":
			DisplayPrompt("Amidst the buried catacombs, you face a shocking sight: someone from your past, long assumed to be dust, now living as a flesh-eating creature of the deep. They share a disturbing tale involving two other characters from your history. Decide if you stay in the deep forever, or take their gift back to the surface.")
			
			var options = ["Accept a bizarre subterranean relic", "Uncover a truth about your past", "Remain here forever"]
			window = GetEvilChoice("Which gift do you accept from this changed soul?", options)
			await window.tree_exited
			
			if evilChoice == "Accept a bizarre subterranean relic":
				window = GetEvilText("Create the strange underground Resource:")
				await window.tree_exited
				resources.append(evilResponse)
			elif(evilChoice == "Remain here forever"):
				endGame = true
			else:
				window = GetEvilText("Create a Skill representing this historical revelation:")
				await window.tree_exited
				skills.append(evilResponse)
				
			evilChoice = null
			evilResponse = ""
		
		"22A":
			DisplayPrompt("You have spent decades acting as a hidden architect, meticulously sculpting a human life from the cradle to young adulthood to serve your exact desires. What did it cost to raise them?")
			
			window = GetEvilText("Create the servant:")
			await window.tree_exited
			mortals.append(evilResponse); evilResponse = ""
			
			window = GetEvilChoice("Lose a Resource spend on their creation or upbringing:", resources)
			await window.tree_exited
			resources.erase(evilChoice); evilChoice = null
		"22B":
			DisplayPrompt("The grand tapestry of your past fades away; you now exist solely in the immediate present, pulling strings from the shadows to survive. Permanently remove a memory slot. You gain the skill 'Feral cunning'")
			var options = GetMemories()
			window = GetEvilChoice("Choose a Memory to discard permanently:", options)
			await window.tree_exited
			memories.remove_at(options.find(evilChoice)); evilChoice = null
			
			skills.append("Feral cunning")
		
		"23A":
			DisplayPrompt("The methods you have relied on to capture prey for generations no longer function in this changing society. What shift in the world has rendered your old hunting habits obsolete?")
			
			window = GetEvilChoice("Lose a resource:", resources)
			await window.tree_exited
			resources.erase(evilChoice); evilChoice = null
			
			window = GetEvilText("Gain a new skill:")
			await window.tree_exited
			skills.append(evilResponse); evilResponse = ""
		"23B":
			DisplayPrompt("Your new approach to feeding demands an exhausting toll from your undead frame. What strenuous labor must you perform just to survive the night?")
			
			window = GetEvilText("Gain a practical, physical skill born of this exertion:")
			await window.tree_exited
			skills.append(evilResponse); evilResponse = ""
			
			var options = GetMemories()
			window = GetEvilChoice("Sacrifice an entire memory to the grueling routine:", options)
			await window.tree_exited
			memories.remove_at(options.find(evilChoice)); evilChoice = null
			memories.append(Memory.new())
		"23C":
			DisplayPrompt("A human uncovers the horrific mechanics of your new feeding system. Instead of panicking, they confront you with a deeply logical or emotionally devastating argument to make you stop. How do you keep them silent?")
			
			if mortals.size() == 0:
				window = GetEvilText("Create the observant mortal:")
				await window.tree_exited
				mortals.append(evilResponse); evilResponse = ""
				
			window = GetEvilChoice("Use a Skill:", skills)
			await window.tree_exited
			usedSkills.append(evilChoice); skills.erase(evilChoice); evilChoice = null
		
		"24A":
			DisplayPrompt("A feeding session goes horribly wrong, accidentally passing the curse of unlife to one of your victims. What stays your hand from immediately ending their unlife?")
			
			if mortals.size() > 0:
				window = GetEvilChoice("Select the mortal to turn:", mortals)
				await window.tree_exited
				immortals.append(evilChoice)
				mortals.erase(evilChoice)
				evilChoice = null
			else:
				window = GetEvilText("Create the mortal victim:")
				await window.tree_exited
				immortals.append(evilResponse); evilResponse = ""
				
			window = GetEvilChoice("Use a skill:", skills)
			await window.tree_exited
			usedSkills.append(evilChoice); skills.erase(evilChoice); evilChoice = null
		"24B":
			DisplayPrompt("Your accidental progeny haunts the periphery of your life, growing into a grotesque caricature of your own worst traits. How do they mock your nature? What disturbing token or object do they leave you with?")
			
			window = GetEvilText("Create the disturbing resource:")
			await window.tree_exited
			resources.append(evilResponse); evilResponse = ""
		"24C":
			DisplayPrompt("Your creation has been captured by mortals, threatening to drag your existence into the light. Do you attempt a desperate rescue, or let them burn and suffer the consequences?")
			
			var options = ["Attempt a rescue (Check 3 Skills)", "Abandon them to their fate (Lose 3 Resources)"]
			window = GetEvilChoice("Choose your approach:", options)
			await window.tree_exited
			
			if evilChoice == "Attempt a rescue (Check 3 Skills)":
				window = GetEvilChoice("Use a skill:", skills)
				await window.tree_exited
				usedSkills.append(evilChoice); skills.erase(evilChoice); evilChoice = null
				
				window = GetEvilChoice("Use another skill:", skills)
				await window.tree_exited
				usedSkills.append(evilChoice); skills.erase(evilChoice); evilChoice = null
				
				window = GetEvilChoice("Use a final skill:", skills)
				await window.tree_exited
				usedSkills.append(evilChoice); skills.erase(evilChoice); evilChoice = null
			else:
				window = GetEvilChoice("Lose a resource:", resources)
				await window.tree_exited
				resources.erase(evilChoice) ; evilChoice = null
				
				window = GetEvilChoice("Lose another resource:", resources)
				await window.tree_exited
				resources.erase(evilChoice) ; evilChoice = null
				
				window = GetEvilChoice("Lose a final resource:", resources)
				await window.tree_exited
				resources.erase(evilChoice) ; evilChoice = null
			evilChoice = null
			
		"25A":
			DisplayPrompt("A brutal war tears through the country you call home. What do you lose in the conflict?")
			
			window = GetEvilChoice("Lose a resource:", resources)
			await window.tree_exited
			resources.erase(evilChoice); evilChoice = null
		"25B":
			DisplayPrompt("Your highly secretive behavior catches the attention of military authorities, and you are captured under suspicion of espionage. Decide how you escape your captors.")

			var options = ["Use a Skill to break out", "Suffer through experimentation (Lose a Resource, gain a Mark)"]
			window = GetEvilChoice("Choose your escape method:", options)
			await window.tree_exited

			if evilChoice == "Use a Skill to break out":
				window = GetEvilChoice("Check a Skill used to escape:", skills)
				await window.tree_exited
				usedSkills.append(evilChoice); skills.erase(evilChoice); evilChoice = null
			else:
				window = GetEvilChoice("Choose a Resource confiscated by the military:", resources)
				await window.tree_exited
				resources.erase(evilChoice); evilChoice = null
				
				window = GetEvilText("Record the grotesque Mark left by their horrific experiments:")
				await window.tree_exited
				marks.append(evilResponse); evilResponse = ""
				
			evilChoice = null
			
			window = GetEvilText("Create a well-funded mortal director who now hunts anomalous entities:")
			await window.tree_exited
			mortals.append(evilResponse); evilResponse = ""
		"25C":
			DisplayPrompt("Leaning into their suspicions, you become a literal spy, selling the secrets of your homeland to foreign powers for immense wealth. What half-forgotten talent of yours now comes in handy?")
			
			# Gain two resources from treason
			for i in range(2):
				window = GetEvilText("Gain a Resource from your foreign handlers (%d of 2):" % (i + 1))
				await window.tree_exited
				resources.append(evilResponse); evilResponse = ""
				
			window = GetEvilChoice("Check a Skill to carry out your clandestine operations:", skills)
			await window.tree_exited
			usedSkills.append(evilChoice); skills.erase(evilChoice); evilChoice = null
			
			window = GetEvilText("Gain a new Skill related to statecraft, forgery, or espionage:")
			await window.tree_exited
			skills.append(evilResponse); evilResponse = ""
			
			# Restore/uncheck an ancient skill
			if usedSkills.size() > 0:
				window = GetEvilChoice("Uncheck an old, surprising Skill that has unexpectedly become relevant again:", usedSkills)
				await window.tree_exited
				skills.append(evilChoice); usedSkills.erase(evilChoice); evilChoice = null
				
			# Select a sacrificial character
			var characters = mortals.duplicate()
			characters.append_array(immortals.duplicate())
			if characters.size() > 0:
				window = GetEvilChoice("Which character suffers and dies because of your treason?", characters)
				await window.tree_exited
				deceasedCharacters.append(evilChoice)
				if mortals.has(evilChoice): mortals.erase(evilChoice)
				else: immortals.erase(evilChoice)
				evilChoice = null
			else:
				window = GetEvilText("No one you know was left to die. Create a mortal ally who trusted you and was executed for your crimes:")
				await window.tree_exited
				deceasedCharacters.append(evilResponse); evilResponse = ""
		
		"26A":
			DisplayPrompt("A deceased mortal from your deep past now walks back into your life. How did they cheat the grave, and what do they demand of you? If you have no memories left of them, how do you finally recognize them?")
			
			if deceasedCharacters.size() > 0:
				window = GetEvilChoice("Select a deceased mortal who returns from the grave:", deceasedCharacters)
				await window.tree_exited
				mortals.append(evilChoice)
				deceasedCharacters.erase(evilChoice)
				evilChoice = null
			else:
				window = GetEvilText("Create a supposedly dead figure from your past who stands before you once more:")
				await window.tree_exited
				mortals.append(evilResponse); evilResponse = ""
				
			window = GetEvilChoice("Use a skill:", skills)
			await window.tree_exited
			usedSkills.append(evilChoice); skills.erase(evilChoice); evilChoice = null
		"26B":
			DisplayPrompt("The returned mortal has brought a catastrophic danger directly to your doorstep. What nightmare, entity, or agency has tracked them to you?")
			
			var enemy_types = ["Mortal Adversary", "Immortal Adversary"]
			window = GetEvilChoice("What is the nature of this new threat?", enemy_types)
			await window.tree_exited
			
			if evilChoice == "Mortal Adversary":
				window = GetEvilText("Create this mortal enemy:")
				await window.tree_exited
				mortals.append(evilResponse)
			else:
				window = GetEvilText("Create this immportal enemy:")
				await window.tree_exited
				immortals.append(evilResponse)
			evilChoice = null; evilResponse = ""
			
			# Cost choice
			var cost_options = ["Check a Skill to counter them", "Sacrifice a Resource to buy safety"]
			window = GetEvilChoice("How do you survive their initial strike?", cost_options)
			await window.tree_exited
			
			if evilChoice == "Check a Skill to counter them":
				window = GetEvilChoice("Choose a Skill to check:", skills)
				await window.tree_exited
				usedSkills.append(evilChoice); skills.erase(evilChoice); evilChoice = null
			else:
				window = GetEvilChoice("Choose a Resource to forfeit:", resources)
				await window.tree_exited
				resources.erase(evilChoice); evilChoice = null
		
		"27A":
			DisplayPrompt("Your monstrous nature is exposed to the local populace, forcing you to flee to another country. What must you leave behind?")
			
			window = GetEvilChoice("Select a stationary Resource to lose:", resources)
			await window.tree_exited
			resources.erase(evilChoice); evilChoice = null
		"27B":
			DisplayPrompt("To escape further scrutiny, you craft an entirely mundane alter ego. Replace a memory with this blandly modern persona. Gain a Skill centered around blending into crowds and avoiding notice.")
			
			var options = GetMemories()
			window = GetEvilChoice("Select a memory:", options)
			await window.tree_exited
			memories.remove_at(options.find(evilChoice)) ; evilChoice = null
			
			window = GetEvilText("Create a Skill based on hiding in plain sight or acting unremarkable:")
			await window.tree_exited
			skills.append(evilResponse); evilResponse = ""
		
		"28A":
			DisplayPrompt("The behavioral norms of the living have completely ceased to make sense to you. What basic human custom have you forgotten how to perform?")
			
			window = GetEvilChoice("Use a skill:", skills)
			await window.tree_exited
			skills.erase(evilChoice); evilChoice = null
		"28B":
			DisplayPrompt("You become enthralled in a passionate love that breaks a local culture's rigid taboo. Who is this person, and why must your bond remain strictly in the shadows?")
			
			window = GetEvilText("Create this forbidden lover (Mortal):")
			await window.tree_exited
			mortals.append(evilResponse); evilResponse = ""
			
			window = GetEvilChoice("Use a resource to keep the secret love safe:", resources)
			await window.tree_exited
			resources.erase(evilChoice); evilChoice = null
		"28C":
			DisplayPrompt("You completely dismantle your old personality and forge a brand new framework for how you perceive and interact with the world around you.")
			
			if usedSkills.size() > 0:
				window = GetEvilChoice("Uncheck a Skill, restoring it to your active pool:", usedSkills)
				await window.tree_exited
				skills.append(evilChoice); usedSkills.erase(evilChoice); evilChoice = null
		
		"29A":
			DisplayPrompt("A lethargy overcomes you, and you sink into an unbroken slumber that lasts a whole century. When you finally awaken, the mortal world has moved on without you. Remove every mortal.")
			for mortal in mortals:
				deceasedCharacters.append(mortal)
			mortals.clear()
		"29B":
			DisplayPrompt("You encounter a living mortal who is the direct descendant of someone from your past - someone who still lives on in one of your active memories. How do you share details about their ancestor without exposing your true nature?")
			
			window = GetEvilText("Gain a skill:")
			await window.tree_exited
			skills.append(evilResponse); evilResponse = ""
			
			window = GetEvilText("Create the mortal descendant:")
			await window.tree_exited
			mortals.append(evilResponse); evilResponse = ""
		"29C":
			DisplayPrompt("While digging through old family archives, your new friend unearths historical records that unmask you completely. How does your relationship warp now that they know what you are?")
		
		"30A":
			DisplayPrompt("You keep a human locked away in your domain. Why have you singled out this specific person, and what dark purpose restrains you from simply draining them dry?")
			
			window = GetEvilText("Create your mortal prisoner:")
			await window.tree_exited
			mortals.append(evilResponse); evilResponse = ""
			
			window = GetEvilText("Gain a Skill related to keeping them captive or breaking their spirit:")
			await window.tree_exited
			skills.append(evilResponse); evilResponse = ""
		"30B":
			DisplayPrompt("A group of daring mortals breaches your sanctuary, staging a chaotic rescue operation to liberate your prisoner. What is lost in the skirmish?")
			
			window = GetEvilChoice("Lose a resource:", resources)
			await window.tree_exited
			resources.erase(evilChoice); evilChoice = null
			
			# Create two rescuers
			for i in range(2):
				window = GetEvilText("Create a mortal rescuer (%d of 2):" % (i + 1))
				await window.tree_exited
				mortals.append(evilResponse); evilResponse = ""
		"30C":
			DisplayPrompt("In a bizarre turn of events, your former captive walks back into your lair completely voluntarily - but they do so on their own terms, dictating the conditions of their presence. What has changed to warp this dynamic?")
		
		"31A":
			DisplayPrompt("You possess rare, ancient knowledge regarding where historical artifacts and long-lost secrets are buried. What priceless truth or relic do you offer up to mend fences with an adversary?")
			
			window = GetEvilText("Create an antique or historical Resource you uncovered:")
			await window.tree_exited
			resources.append(evilResponse); evilResponse = ""
		"31B":
			DisplayPrompt("A violent revolution completely overturns the local power structure. Who rises to exploit this vacuum? How do you survive the revolutionary chaos?")
			
			window = GetEvilChoice("Use a skill", skills)
			await window.tree_exited
			usedSkills.append(evilChoice); skills.erase(evilChoice); evilChoice = null
			
			var paths = ["Collaborate (Gain resource and skill)", "Resist (Use two skills)"]
			window = GetEvilChoice("How do you handle the new regime?", paths)
			await window.tree_exited
			
			if evilChoice == "Collaborate (Gain resource and skill)":
				window = GetEvilText("Create a resource from exploitation:")
				await window.tree_exited
				resources.append(evilResponse); evilResponse = ""
				skills.append("Join the winning side")
			else:
				for i in range(2):
					if skills.size() > 0:
						window = GetEvilChoice("Use a skill (%d of 2):" % (i + 1), skills)
						await window.tree_exited
						usedSkills.append(evilChoice); skills.erase(evilChoice); evilChoice = null
						
			evilChoice = null
		
		"32A":
			DisplayPrompt("A wave of fury takes hold of you, causing you to destroy something of immense personal value. When the red mist clears, what have you shattered?")
			
			var penalty_options = ["Sacrifice a memory to the rage", "Destroy a valuable resource"]
			window = GetEvilChoice("What did your fury consume?", penalty_options)
			await window.tree_exited
			
			if evilChoice == "Sacrifice a Memory to the rage":
				var current_memories = GetMemories()
				if current_memories.size() > 0:
					window = GetEvilChoice("Choose a memory:", current_memories)
					await window.tree_exited
					memories.remove_at(current_memories.find(evilChoice))
					memories.append(Memory.new())
			else:
				if resources.size() > 0:
					window = GetEvilChoice("Select a Resource that you destroyed in your madness:", resources)
					await window.tree_exited
					resources.erase(evilChoice)
					
			evilChoice = null
		"32B":
			DisplayPrompt("Your violence-filled blackouts leave you deeply shaken. Do you expend immense willpower trying to chain the beast within, or do you fully surrender to the horror of your nature?")
			
			if mortals.size() > 0:
				window = GetEvilChoice("Select a mortal who falls victim to your latest frenzy:", mortals)
				await window.tree_exited
				deceasedCharacters.append(evilChoice)
				mortals.erase(evilChoice); evilChoice = null
			else:
				window = GetEvilText("Record a distressing Mark:")
				await window.tree_exited
				marks.append(evilResponse); evilResponse = ""
		"32C":
			DisplayPrompt("In a frantic bid to excise the last vestiges of mortal weakness, you tear the flesh from your own face. How do you mask your awful new visage from the world?")
			
			window = GetEvilText("Gain a mark:")
			await window.tree_exited
			marks.append(evilResponse); evilResponse = ""
		
		"33A":
			DisplayPrompt("You cross paths with a living human who is the direct blood descendant of one of your greatest historical enemies. Instead of taking revenge, you unexpectedly step in to aid them. Why do you perform this act of mercy?")
			
			window = GetEvilText("Create this mortal descendant:")
			await window.tree_exited
			mortals.append(evilResponse); evilResponse = ""
			
			window = GetEvilChoice("Use a skill:", skills)
			await window.tree_exited
			usedSkills.append(evilChoice); skills.erase(evilChoice); evilChoice = null
		"33B":
			DisplayPrompt("Mistaking your aid for a deeper allegiance, the descendant you saved attempts to repay your kindness by launching a reckless, violent assault against those they perceive to be your adversaries. Who perishes in the onslaught?")
			
			var characters = mortals.duplicate()
			characters.append_array(immortals.duplicate())
			if characters.size() > 0:
				window = GetEvilChoice("Select a character to die:", characters)
				await window.tree_exited
				deceasedCharacters.append(evilChoice)
				if mortals.has(evilChoice): mortals.erase(evilChoice)
				else: immortals.erase(evilChoice)
				evilChoice = null
		"33C":
			DisplayPrompt("The fallout from their reckless crusade has trapped the descendant in immediate, mortal danger. Will you step into the line of fire to save your enemy's bloodline?")
			
			var options = ["Use a skill to rescue them", "Sacrifice a resource to buy their safety", "Abandon them to their terrible fate"]
			window = GetEvilChoice("Choose your approach:", options)
			await window.tree_exited
			
			if evilChoice == "Use a skill to rescue them":
				window = GetEvilChoice("Select the Skill used to save them:", skills)
				await window.tree_exited
				usedSkills.append(evilChoice); skills.erase(evilChoice); evilChoice = null
			elif evilChoice == "Sacrifice a resource to buy their safety":
				window = GetEvilChoice("Select a Resource to forfeit:", resources)
				await window.tree_exited
				resources.erase(evilChoice); evilChoice = null
			else:
				window = GetEvilChoice("Choose the mortal who must die:", mortals)
				await window.tree_exited
				deceasedCharacters.append(evilChoice) ; mortals.erase(evilChoice)
			evilChoice = null
		
		"34A":
			DisplayPrompt("Your web of lies has begun to warp your own perception of history. Combine any three existing resources/skills/marks/characters to fabricate a completely fictional experience that your mind fully accepts as absolute truth. Append (THIS IS A LIE) to the experience.")
		"34B":
			DisplayPrompt("Driven by the absolute certainty of your false memory, you seek out a character to punish them for an offense they never actually committed. Kill them in your righteous fury. Gain the skill 'I know what's real'.")
			
			var characters = mortals.duplicate()
			characters.append_array(immortals.duplicate())
			if characters.size() > 0:
				window = GetEvilChoice("Select the character you choose to punish for your delusion:", characters)
				await window.tree_exited
				deceasedCharacters.append(evilChoice)
				if mortals.has(evilChoice): mortals.erase(evilChoice)
				else: immortals.erase(evilChoice)
				evilChoice = null
			else:
				window = GetEvilText("With no one left around you, create a new mortal target who suffers your wrath:")
				await window.tree_exited
				deceasedCharacters.append(evilResponse); evilResponse = ""
				
			window = GetEvilChoice("Check a Skill to execute your misplaced vengeance:", skills)
			await window.tree_exited
			usedSkills.append(evilChoice); skills.erase(evilChoice); evilChoice = null
			
			skills.append("I know what's real")
		"34C":
			DisplayPrompt("A stark, undeniable truth violently shatters your worldview: an anchor-point memory you have relied upon for ages is exposed as a complete hallucination. Erase a memory.")
			
			var current_memories = GetMemories()
			if current_memories.size() > 0:
				window = GetEvilChoice("Choose the memory to erase:", current_memories)
				await window.tree_exited
				memories.remove_at(current_memories.find(evilChoice)); evilChoice = null
				memories.append(Memory.new())
		
		"35A":
			DisplayPrompt("The world decays around you. You look upon an old asset, completely unable to remember why you kept it or what it meant to you. Forfeit a Resource for which you hold no corresponding Memory. Do not record an experience for this prompt.")
			
			window = GetEvilChoice("Select a forgotten Resource to wither away into dust:", resources)
			await window.tree_exited
			resources.erase(evilChoice); evilChoice = null
			recordExperience = false
		"35B":
			DisplayPrompt("You find yourself executing maneuvers entirely by muscle memory, unable to recall why you ever learned them. Unnerved by your own automated existence, you lose a skill for which you have no corresponding Memory.")
			
			window = GetEvilChoice("Choose a skill to lose:", skills)
			await window.tree_exited
			skills.erase(evilChoice); evilChoice = null
		"35C":
			DisplayPrompt("Your habits have become opressive rote. A relentless adversary corners you, nearly ending your existence because they charted your movements. Break an existing Resource, and remake it into something entirely new and surprising to throw off your hunters.")
			
			window = GetEvilChoice("Select a Resource to break and dismantle:", resources)
			await window.tree_exited
			resources.erase(evilChoice); evilChoice = null
			
			window = GetEvilText("Create a completely new, surprising Resource forged from its remains:")
			await window.tree_exited
			resources.append(evilResponse); evilResponse = ""
		
		"36A":
			DisplayPrompt("The delicate structures of your once-human intellect begin to dissolve, focusing your entire existence purely into sharp sensory inputs and raw, driving hunger. What animalistic traits have overridden your baseline consciousness?")
			
			window = GetEvilText("Create a skill reflecting your feral vampire nature:")
			await window.tree_exited
			skills.append(evilResponse); evilResponse = ""
			
			var current_memories = GetMemories()
			window = GetEvilChoice("Select an existing Memory to be consumed by your predatory instincts:", current_memories)
			await window.tree_exited
			memories.remove_at(current_memories.find(evilChoice)); evilChoice = null
			memories.append(Memory.new())
		"36B":
			DisplayPrompt("Your gait and posture have warped into something purely predatory. Even when trying to stand perfectly still, mortals unconsciously perceive the terrifying wrongness of your fluid movements.")
			
			window = GetEvilText("Record a mark detailing your unsettling physical presence:")
			await window.tree_exited
			marks.append(evilResponse); evilResponse = ""
		"36C":
			DisplayPrompt("Your eyes can instantly isolate the best potential targets in even a dense crowd. You gain the skill 'Cull the herd'.")
			skills.append("Cull the herd")
		
		"37A":
			DisplayPrompt("Whenever the sun rises you enter a state of absolute, helpless vulnerability. Where do you conceal your physical form while you sleep, and what defensive measures protect your resting place?")
			
			window = GetEvilChoice("Check a Skill used to secure your daytime sanctuary:", skills)
			await window.tree_exited
			usedSkills.append(evilChoice); skills.erase(evilChoice); evilChoice = null
			
			window = GetEvilText("Create a protective Resource representing your hidden lair or its defenses:")
			await window.tree_exited
			resources.append(evilResponse); evilResponse = ""
			
			var options = ["Yes, employ a daytime guardian", "No, rely strictly on your traps and secrecy"]
			window = GetEvilChoice("Do you recruit a mortal servant to guard your slumber?", options)
			await window.tree_exited
			
			if evilChoice == "Yes, employ a daytime guardian":
				window = GetEvilText("Create your mortal daylight servant:")
				await window.tree_exited
				mortals.append(evilResponse)
				
			evilChoice = null; evilResponse = ""
		"37B":
			DisplayPrompt("An otherworldly entity manifests before you, dragging your mind into a surreal journey across impossible landscapes. They offer you spiritual solace in exchange for a terrifying pledge. What price do they demand?")
			
			var options = ["Accept the entity's bargain (Gain an arcane skill)", "Refuse their terrifying terms"]
			window = GetEvilChoice("Will you swear the pledge?", options)
			await window.tree_exited
			
			if evilChoice == "Accept the entity's bargain (Gain an arcane skill)":
				window = GetEvilText("Create an unearthly skill granted by this alien communion:")
				await window.tree_exited
				skills.append(evilResponse)
				
			evilChoice = null; evilResponse = ""
		"37C":
			DisplayPrompt("With the veil of material reality torn asunder, and the ancient entities that inhabit that space having been exposed to you, your mind can never return to its comfortable ignorance. For the rest of the game, tainty your experiences with this otherworldly influence. Gain the skill 'I see inbetween'.")
			skills.append("I see inbetween")
		
		"38A":
			DisplayPrompt("Your physical and mental biology has drifted permanently out of alignment with the human experience. The capacity of your intellect degrades. What nameless title or cold alias do you use now?")
			
			var options = GetMemories()
			window = GetEvilChoice("Your mind shrinks. Choose a Memory to discard permanently:", options)
			await window.tree_exited
			memories.remove_at(options.find(evilChoice)); evilChoice = null
			
			window = GetEvilText("Update your name:")
			await window.tree_exited
			vampireName = evilResponse ; evilResponse = ""
		"38B":
			DisplayPrompt("An archaic social superstition from a deeply buried era of your past has become completely hardwired into your nervous system. How does this rule hinder you?")
			
			window = GetEvilText("Record a Mark representing this psychological compulsion or ritualistic curse:")
			await window.tree_exited
			marks.append(evilResponse); evilResponse = ""
		"38C":
			DisplayPrompt("A silent phantom begins to shadow your steps. You cannot discern if it is a restless soul or merely a vivid hallucination born of your rotting sanity.")
			
			if deceasedCharacters.size() > 0:
				window = GetEvilChoice("Select a long-dead character who returns to haunt you as a spirit:", deceasedCharacters)
				await window.tree_exited
				immortals.append(evilChoice + "(phantom)")
				deceasedCharacters.erase(evilChoice)
				evilChoice = null
			else:
				window = GetEvilText("Create the phantom:")
				await window.tree_exited
				immortals.append(evilResponse + " (phantom)"); evilResponse = ""
		
		"39A":
			DisplayPrompt("The modern world advances at a terrifying pace. What piece of contemporary technology are you completely unable to interact with due to your vampire nature? How did your first encounter with it almost result in your absolute destruction?")
			
			window = GetEvilChoice("Use a skill to survive this modern technological hazard:", skills)
			await window.tree_exited
			usedSkills.append(evilChoice); skills.erase(evilChoice); evilChoice = null
		"39B":
			DisplayPrompt("You find brief solace in the company of a group of humans who share your hyperfixation on a specific resource you possess. Is this a club, a subculture, or true friendship?")
			
			window = GetEvilText("Develop a new skill born from your deep expertise with this resource:")
			await window.tree_exited
			skills.append(evilResponse); evilResponse = ""
			
			for i in range(3):
				window = GetEvilText("Create a mortal companion who shares your obsession (%d of 3):" % (i + 1))
				await window.tree_exited
				mortals.append(evilResponse); evilResponse = ""
		"39C":
			DisplayPrompt("Decades slip by. You remain ageless while your companions slowly wither and dry up around you. You must abandon them or be exposed. What do you feel at your last meeting, knowing that this is the end?")
			
			if mortals.size() > 0:
				for mortal in mortals:
					deceasedCharacters.append(mortal)
				mortals.clear()
		
		"40A":
			DisplayPrompt("An immortal from your past steps out of the shadows to collect an outstanding debt. What terrible price do they demand, and how has the weight of centuries warped them?")
			
			var options = ["I remember this immortal (Lose 2 resources)", "I have no memory of them (Lose 3 resources & use a skill)"]
			window = GetEvilChoice("Do you remember this immortal debt-collector?", options)
			await window.tree_exited
			
			if evilChoice == "I remember this immortal (Lose 2 resources)":
				for i in range(2):
					if resources.size() > 0:
						window = GetEvilChoice("Surrender a resource to satisfy the debt (%d of 2):" % (i + 1), resources)
						await window.tree_exited
						resources.erase(evilChoice); evilChoice = null
			else:
				for i in range(3):
					if resources.size() > 0:
						window = GetEvilChoice("Forfeit a resource in the chaos (%d of 3):" % (i + 1), resources)
						await window.tree_exited
						resources.erase(evilChoice); evilChoice = null
						
				window = GetEvilChoice("Use a skill to survive their unannounced wrath:", skills)
				await window.tree_exited
				usedSkills.append(evilChoice); skills.erase(evilChoice); evilChoice = null
				
			evilChoice = null
		"40B":
			DisplayPrompt("What parting cruelty or devastating revelation did an immortal inflict upon you to send your mind spiraling into absolute, pitch-black despair? Erase your oldest memory and gain a skill forged of despair.")
			
			var options = GetMemories()
			window = GetEvilChoice("Choose your oldest memory:", options)
			await window.tree_exited
			memories.remove_at(options.find(evilChoice)) ; evilChoice = null
			memories.append(Memory.new())
			
			window = GetEvilText("Gain a grim skil:")
			await window.tree_exited
			skills.append(evilResponse); evilResponse = ""
		"40C":
			DisplayPrompt("You construct a meticulous plot of vengeance and execute it with cold-blooded efficiency, unleashing absolute ruin upon an immortal peer.")
			
			window = GetEvilChoice("Use a skill to execute your ruthless counter-strike:", skills)
			await window.tree_exited
			usedSkills.append(evilChoice); skills.erase(evilChoice); evilChoice = null
			
			var strike_options = ["Violently reclaim a lost resource", "Destroy the immortal character permanently"]
			window = GetEvilChoice("What is the final outcome of your vengeance?", strike_options)
			await window.tree_exited
			
			if evilChoice == "Violently reclaim a lost resource":
				window = GetEvilText("Create or reclaim a powerful resource taken from their hoard:")
				await window.tree_exited
				resources.append(evilResponse); evilResponse = ""
			else:
				if immortals.size() > 0:
					window = GetEvilChoice("Select the immortal character who is put to the sword:", immortals)
					await window.tree_exited
					deceasedCharacters.append(evilChoice)
					immortals.erase(evilChoice); evilChoice = null
					
			evilChoice = null
		
		"41A":
			DisplayPrompt("You are caught and unmasked. How do they destroy you?")
			endGame = true
		
		"42A":
			DisplayPrompt("You achieve a state of absolute, unbreakable security - a perfect equilibrium that could sustain your existence until the sun burns itself out. What does this flawless isolation look like? The game is over.")
			endGame = true
		
		"43A":
			DisplayPrompt("You are physically entombed in a forgotten place from which you will never be rescued. What regrets occupy your mind for the first thousand years of darkness? The game is over.")
			endGame = true
		
		"44A":
			DisplayPrompt("A figure from your deep past slips through your defences and silently murders you in your sleep. The game is over.")
			
			var characters = mortals.duplicate()
			characters.append_array(immortals.duplicate())
			characters.append_array(deceasedCharacters.duplicate())
			
			if characters.size() > 0:
				window = GetEvilChoice("Select the figure from your history who delivers the killing blow:", characters)
				await window.tree_exited
				evilChoice = null
			endGame = true
		
		"45A":
			DisplayPrompt("Your ancient body finally reaches its limits. You can no longer execute the hunting patterns required to sustain your feed. What happens as your spark flickers out? The game is over.")
			endGame = true
	
		"46A":
			DisplayPrompt("The secret world is revealed and supernatural creatures like yourself have conquered humanity. What is your position in this grim, triumphant new world order? The game is over.")
			endGame = true
	
	
	UpdateGraphics()
	
	if(recordExperience):
		window = GetEvilText("Write an Experience for this event, summing it up from your character's perspective in ~20 words:")
		await window.tree_exited
		
		#make sure we're only sending memories that have room
		var allMemories = GetMemories()
		var options = allMemories.duplicate()
		var i = 0
		for m in memories:
			if(m.experiences.size() >= 3): options.remove_at(i)
			else: i += 1
		
		#erase a memory if we've run out of space
		if(options.size() == 0):
			options = GetMemories()
			window = GetEvilChoice("You must make space to record this new experience. Choose a memory that fades into the past:", options)
			await window.tree_exited
			memories.remove_at(options.find(evilChoice))
			memories.append(Memory.new())
			memories.back().experiences.append(evilResponse)
		else:
			window = GetEvilChoice("Choose a memory to add this experience to:", options)
			await window.tree_exited
			memories[allMemories.find(evilChoice)].experiences.append(evilResponse)
		evilChoice = null
		evilResponse = ""
	
	UpdateGraphics()
	
	if(!noMatch): # usually this will only fail if there's no B/C prompt
		await get_tree().create_timer(5).timeout
	if(endGame): 
		GameOver()
		print("End of the game")
	else: 
		
		var actionWindow := ActionWindow.new(self)
		actionWindow.set_force(0, "Send CONTINUE to go to the next prompt.", "", false, ActionsForce.Priority.LOW)
		actionWindow.add_action(NeuroText.new(self, actionWindow)) ; actionWindow.register()
		await actionWindow.tree_exited
		
		NextPrompt()


func UpdateGraphics():
	get_node("CanvasLayer/Book/Character/Name").text = vampireName
	
	var memoriesText = ""
	for m in memories:
		for e in m.experiences:
			memoriesText += "- " + e + "\n"
		memoriesText += "\n"
	UpdateText(get_node("CanvasLayer/Book/Character/Memories/Label"), memoriesText)
	
	var expendablesText = "Characters:\n"
	for c in mortals:
		expendablesText += "- " + c + "\n"
	for c in immortals:
		expendablesText += "- " + c + "\n"
	
	expendablesText += "\nSkills:\n"
	for s in skills:
		expendablesText += "- " + s + "\n"
	
	expendablesText += "\nResources:\n"
	for r in resources:
		expendablesText += "- " + r + "\n"
	
	expendablesText += "\nMarks:\n"
	for m in marks:
		expendablesText += "- " + m + "\n"
	
	UpdateText(get_node("CanvasLayer/Book/Expendables/Label"), expendablesText) # scales the text box to fit


var textQueue = []
var currentTQID = 0

func UpdateText(label, text):
	
	var tqID = currentTQID
	currentTQID += 1
	textQueue.append(tqID)
	while(textQueue[0] != tqID):
		await get_tree().process_frame
	
	sfxPlayer.stream = scribbleSFX.pick_random()
	sfxPlayer.play()
	
	var old_text = label.text
	if old_text == text:
		textQueue.remove_at(0)
		return
	
	# 1. Find Common Prefix (Starts from the top)
	var prefix_len = 0
	var min_len = mini(old_text.length(), text.length())
	for i in min_len:
		if old_text[i] == text[i]:
			prefix_len += 1
		else:
			break

	# 2. Find Common Suffix (Starts from the bottom)
	# We limit this so the suffix doesn't accidentally overlap the prefix
	var suffix_len = 0
	var old_rem = old_text.length() - prefix_len
	var new_rem = text.length() - prefix_len
	var min_rem = mini(old_rem, new_rem)
	
	for i in min_rem:
		if old_text[old_text.length() - 1 - i] == text[text.length() - 1 - i]:
			suffix_len += 1
		else:
			break

	# 3. Isolate the middle chunks that changed
	var old_mid_len = old_text.length() - prefix_len - suffix_len
	var new_mid_len = text.length() - prefix_len - suffix_len
	
	# Extract the static parts of the string
	var prefix_str = old_text.substr(0, prefix_len)
	var suffix_str = old_text.substr(old_text.length() - suffix_len)
	var new_mid_str = text.substr(prefix_len, new_mid_len)

	var tween = label.create_tween()
	# Ensure label shows full text, since we are mutating the string data itself now
	label.visible_characters = -1 

	# 4. "Backspace" Phase: Shrink the old middle chunk down to nothing
	if old_mid_len > 0:
		var delete_duration = old_mid_len * 0.015 # 0.015s per backspace
		tween.tween_method(
			func(chars_removed: int):
				var current_mid = old_text.substr(prefix_len, old_mid_len - chars_removed)
				label.text = prefix_str + current_mid + suffix_str
				, 0, old_mid_len, delete_duration
		)

	# 5. "Typing" Phase: Grow the new middle chunk from nothing
	if new_mid_len > 0:
		var type_duration = new_mid_len * 0.025 # 0.04s per keystroke
		tween.tween_method(
			func(chars_added: int):
				var current_mid = new_mid_str.substr(0, chars_added)
				label.text = prefix_str + current_mid + suffix_str
				, 0, new_mid_len, type_duration
		)
	
	await tween.finished
	textQueue.remove_at(0)


func ScaleText(node):
	# Reset scale to 1.0 before calculating
	node.scale = Vector2.ONE
	var container_height = node.get_parent_control().size.y
	var text_height = node.get_minimum_size().y
	# Only scale down if the text is higher than the container
	if text_height > container_height:
		var scale_factor = container_height / text_height
		node.scale = Vector2(scale_factor, scale_factor)
		node.position = Vector2.ZERO


func DisplayPrompt(context):
	noMatch = false
	Context.send(context)
	var newP = promptGraphic.instantiate()
	get_node("CanvasLayer/Prompts").add_child(newP)
	newP.get_node("Label").text = context

func GetEvilText(prompt = "Write your choice."):
	var actionWindow := ActionWindow.new(self)
	actionWindow.set_force(0, prompt, "", false, ActionsForce.Priority.MEDIUM)
	actionWindow.add_action(NeuroText.new(self, actionWindow))
	actionWindow.register()
	return actionWindow

func GetEvilChoice(prompt = "Make a choice:", options = []):
	if((options == skills or options == resources) and options.size() == 0):
		endGame = true
		var falseWindow = Node.new() ; add_child(falseWindow)
		Context.send("You have no resources/skills to spend. Narrate how your vampire perishes.")
		print("You have no resources/skills to spend. Narrate how your vampire perishes.")
		UpdateGraphics()
		return falseWindow
	
	var actionWindow := ActionWindow.new(self)
	actionWindow.set_force(0, prompt, "", false, ActionsForce.Priority.MEDIUM)
	actionWindow.add_action(NeuroChoice.new(self, options, actionWindow))
	actionWindow.register()
	return actionWindow


func GameOver():
	Context.send("The game is over, the tragedy concluded. Well played, give yourself a cookie.")
	var book = get_node("CanvasLayer/Book")
	var tween = get_tree().create_tween()
	tween.tween_property(book, "modulate", Color(1,1,1,0), 7)
	
	await tween.finished
	var options = ["Play again!", "Let's do something else"]
	var window = GetEvilChoice("What would you like to do now?", options)
	await window.tree_exited
	if(evilChoice == "Play again!"):
		get_tree().reload_current_scene()
	else:
		get_tree().quit()


func GetMemories():
	var summedMemories = []
	var i = 1
	for m in memories:
		var summary = "Memory " + str(i) + ":"
		for e in m.experiences:
			summary += "\n" + e
		summedMemories.append(summary)
	return summedMemories





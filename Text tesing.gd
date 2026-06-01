extends Node


var actualText = ""

# Called when the node enters the scene tree for the first time.
func _ready():
	actualText = "This is a test. We are testing\nTesting."
	UpdateText(actualText, self)
	
	await get_tree().create_timer(3).timeout
	actualText += "\nA surprise!"
	UpdateText(actualText, self)
	
	await get_tree().create_timer(3).timeout
	actualText += "\nAnd now for an incredibly long line that attempts to see if we can make it hiccup, or rather to avoid said hiccup."
	UpdateText(actualText, self)
	
	await get_tree().create_timer(.1).timeout
	actualText = actualText.replace("A surprise!", "YAY!")
	UpdateText(actualText, self)
	
	await get_tree().create_timer(3).timeout
	actualText += "\nWoohooooo!"
	UpdateText(actualText, self)


var textQueue = []
var currentTQID = 0

func UpdateText(text, label):
	
	var tqID = currentTQID
	currentTQID += 1
	
	print("Added text queue " + str(tqID))
	textQueue.append(tqID)
	while(textQueue[0] != tqID):
		await get_tree().process_frame
	print("Processing " + str(tqID))
	
	
	
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
	print("Finished " + str(tqID))

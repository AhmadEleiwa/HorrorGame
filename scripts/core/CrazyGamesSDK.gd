extends Node

## CrazyGames SDK v3 Wrapper for Godot 4 Web Exports
## Handles gameplayStart, gameplayStop, happytime, and loading states.
## Safe to run on Desktop / Editor without any errors.

var is_web: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	is_web = OS.has_feature("web")
	if is_web:
		_init_sdk()

func _init_sdk() -> void:
	JavaScriptBridge.eval("""
		if (window.CrazyGames && window.CrazyGames.SDK) {
			window.CrazyGames.SDK.init().then(() => {
				console.log('[CrazyGames] SDK v3 initialized.');
			}).catch((e) => {
				console.warn('[CrazyGames] SDK init note:', e);
			});
		}
	""")

func loading_start() -> void:
	if not is_web: return
	JavaScriptBridge.eval("if (window.CrazyGames?.SDK?.game) window.CrazyGames.SDK.game.loadingStart();")

func loading_stop() -> void:
	if not is_web: return
	JavaScriptBridge.eval("if (window.CrazyGames?.SDK?.game) window.CrazyGames.SDK.game.loadingStop();")

func gameplay_start() -> void:
	if not is_web: return
	JavaScriptBridge.eval("if (window.CrazyGames?.SDK?.game) window.CrazyGames.SDK.game.gameplayStart();")

func gameplay_stop() -> void:
	if not is_web: return
	JavaScriptBridge.eval("if (window.CrazyGames?.SDK?.game) window.CrazyGames.SDK.game.gameplayStop();")

func happy_time() -> void:
	if not is_web: return
	JavaScriptBridge.eval("if (window.CrazyGames?.SDK?.game) window.CrazyGames.SDK.game.happytime();")

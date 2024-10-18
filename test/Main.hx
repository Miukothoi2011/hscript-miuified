import miuified.MiuHScript;

class Main {
	static function main():Void {
		var script = new MiuHScript();
		script.doString("
			//import haxe.Int32;
			import haxe.Json;
		
			function test(?pi:Bool):Float {
				if (!pi) return 0x7fffffff;
				return 3.14;
			}

			var what:Int = 123;
			var wah:Int = 1211212;
			trace(what);
			trace(wah);
			
			function test2() {
			var ahh = {str: 'ii', dsff: true};
				return Json.stringify(ahh);
			}
		");
		trace(script.call("test", [true]));
		trace(script.call("test", []));
		trace(script.call("test2", []));
	}
}
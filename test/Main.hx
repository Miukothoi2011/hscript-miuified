import miuified.MiuHScript;

class Main {
	static function main():Void {
		var script = new MiuHScript();
		script.doString("
			function test(?pi:Bool):Float {
				if (!pi) return 0x7fffffff;
				return 3.14;
			}

			var what:Int = 123;
			var wah:haxe.Int32 = 1211212;
			trace(what);
			trace(wah);
		");
		trace(script.call("test", [true]));
		trace(script.call("test", []));
	}
}
package miuified;

#if sys
import sys.io.File;
import sys.FileSystem;
#end

using StringTools;

import hscript.Interp;
import hscript.Parser;

@:access(hscript.Interp)
@:access(hscript.Parser)
class MiuHScript
{
	public static var _allInstance:Map<String, MiuHScript> = new Map();
	
	public var active:Bool;
	
	private var _destroy:Bool = false;
	
	private var parser:Parser;
	private var interp:Interp;
	
	public var scriptFile(default, null):Null<String> = "";
	
	public var variables(get, never):Map<String, Dynamic>;

	public var presetType:String = "";

	private var locals(get, never):Map<String, Dynamic>;
	private var finalVariables(get, never):Map<String, Dynamic>;

	public var id:Int = 0;
	
	public var returnValue:Dynamic;
	
	public var code:String;
	
	public function new(?scriptFile:String, startExecute:Bool = true)
	{
		parser = new Parser();
		parser.allowJSON = true;
		parser.allowTypes = true;
		parser.allowMetadata = true;
		
		interp = new Interp();
		
		this.active = true;
		
		preset();
		
		if (scriptFile != null && scriptFile.length > 0)
		{
			this.scriptFile = scriptFile;
			_allInstance.set(scriptFile, this);
			if (startExecute) returnValue = doFile(scriptFile);
		}
	}
	
	public inline function setCode(code):String
		return this.code = code;
	
	public function get_variables():Map<String, Dynamic>
		return interp.variables;
	
	public function get_finalVariables():Map<String, Dynamic>
		return interp.finalVariables;
	
	public function get_locals():Map<String, Dynamic>
	{
		var newMap:Map<String, Dynamic> = new Map();
		for (i in interp.locals.keys())
		{
			var v = interp.locals[i];
			if (v != null)
				newMap[i] = v.r;
		}
		return newMap;
	}
	
	public function exists(name:String):Bool
	{
		if (locals.exists(name)) return true;
		if (variables.exists(name)) return true;
		if (finalVariables.exists(name)) return true;
		return false;
	}
	
	public function set(name:String, value:Dynamic, ?setAsFinal:Bool = false):Dynamic
	{
		variables.set(name, value);
		return value;
	}

	public function get(name:String):Dynamic
	{
		for (i in [locals, variables, finalVariables])
		{
			if (i.exists(name))
				return i.get(name);
		}
		return null;
	}
	
	public function remove(name:String):Bool
	{
		for (i in [variables, finalVariables])
		{
			if (i.exists(name)) {
				i.remove(name);
				return true;
			}
		}
		return false;
	}
	
	public function call(name:String, ?args:Array<Dynamic>):Dynamic
	{
		if (args == null) args = [];
		
		var func = get(name); // NOTE: Only load functions from inside code, not from 'interp.variables'
		if (exists(name) && !Reflect.isFunction(func))
		{
			trace('$name is not a function');
			return null;
		}
		else if (!exists(name))
		{
			trace('Function $name does not exist in MiuHScript instance.');
			return null;
		}
		else return Reflect.callMethod(null, func, args);
	}
	
	public function setClass(cl:Class<Dynamic>):MiuHScript
	{
		var clName:String = Type.getClassName(cl);
		if (clName != null)
		{
			var splitCl:Array<String> = clName.split('.');
			if (splitCl.length > 1)
				clName = splitCl[splitCl.length - 1];

			set(clName, cl);
		}
		return this;
	}
	
	public function setClassString(cl:String):MiuHScript
	{
		var cls:Class<Dynamic> = Type.resolveClass(cl);
		if (cls != null)
		{
			var splitStr:Array<String> = cl.split('.');
			if (splitStr.length > 1)
				cl = splitStr[splitStr.length - 1];

			set(cl, cls);
		}
		return this;
	}
	
	public function preset(?type:String = 'mini'):MiuHScript
	{
		this.presetType = type;
		if (type.length > 0 && type.toLowerCase() != 'none')
		{
			var miniClassList:Array<Class<Dynamic>> = [
				Date, DateTools, EReg, Math, Reflect, Std, StringTools, Type,
				#if sys Sys, sys.io.File, sys.FileSystem #end
			];
			var classList:Array<Class<Dynamic>> = {
				var array = miniClassList.copy();
				var array2:Array<Class<Dynamic>> = [
					List, StringBuf, Xml,
					haxe.Http, haxe.Json, haxe.Log, haxe.Serializer, haxe.Unserializer, haxe.Timer,
					#if sys haxe.SysTools, sys.io.Process, sys.io.FileInput, sys.io.FileOutput, #end
				];
				for (i in array2)
					array.push(i);
				array;
			}
			
			switch (type.trim().toLowerCase())
			{
				case 'full': for (i in classList) setClass(i);
				case 'mini': for (i in miniClassList) setClass(i);
			}
		}
		return this;
	}
	
	public function doFile(file:String):Dynamic
	{
		if (this.scriptFile == null) this.scriptFile = file;
		
		var fileToStr:String = null;
		
		var getText:String->String = #if sys
			File.getContent
		#elseif lime
			lime.utils.Assets.getText
		#end;
		inline function fileExists(id:String):Bool
		{
			return #if sys 
				FileSystem.exists(id)
			#elseif lime
				lime.utils.Assets.exists(id)
			#end;
		}
		
		#if (sys || lime)
		if (fileExists(file)) fileToStr = getText(file);
		#else
		fileToStr = "return null;";
		#end
		return doString(fileToStr);
	}
	
	public function doString(code:String):Dynamic
	{
		var ast = parser.parseString(code);
		return interp.execute(ast);
	}

	/*private function typeof(value:Dynamic):String
	{
		var ret:Type.ValueType = Type.typeof(value);

		return switch (ret)
		{
			case TNull: return 'null';
			case TInt: return 'int';
			case TFloat: return 'float';
			case TBool: return 'bool';
			case TObject: 
				if (value is Class) return 'class'; // idk why static class is object but ok.
				return 'object';
			case TFunction: return 'function';
			case TClass(_): return 'instance';
			case TEnum(_): return 'enum';
			default: return 'null';
		}
	}*/

	private function isOfTypes(v1:Dynamic, v2:Array<Dynamic>):Bool
	{
		var ret:Bool = false;
		for (i in v2)
		{
			ret = Std.isOfType(v1, i);
			if (ret == true) break;
		}
		return ret;
	}
}
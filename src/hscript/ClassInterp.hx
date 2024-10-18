typedef ClassInterpField = {
	public var name:String;
	public var isPublic:Bool;
	@:optional public var type:Expr.CType;
	@:optional public var value:Dynamic;
}

class ClassInterp
{
	public var name:String;
	public var extends:String;
	public var fields:Map<String, ClassInterpField>
	
	public function new(name:String, extendss:String, fields:Map<String, ClassInterpField>)
	{
		this.name = name;
		this.extendss = extendss;
		this.fields = fields;
	}
	
	public function toString():String
	{
		return "Class<" + name + ">";
	}
}
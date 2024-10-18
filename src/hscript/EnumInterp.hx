typedef EnumInterpField = {
	public var name:String;
	@:optional public var args:Map<String, Expr.CType>;
}

class EnumInterp
{
	public var name:String;
	public var fields:Map<String, EnumInterpField>
	
	public function new(name:String, fields:Map<String, EnumInterpField>)
	{
		this.name = name;
		this.fields = fields;
	}
	
	public function toString():String
	{
		return "Enum<" + name + ">";
	}
}
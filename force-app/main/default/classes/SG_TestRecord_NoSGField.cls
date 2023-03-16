public class SG_TestRecord_NoSGField extends SG_TestRecord_Abstract {
	override public boolean contains(String fieldName) {
        return false;
    }
    
    override public Object get(String fieldName) {
		return null;
    }
}
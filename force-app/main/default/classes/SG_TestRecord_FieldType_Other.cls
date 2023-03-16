public class SG_TestRecord_FieldType_Other extends SG_TestRecord_Abstract {
	override public boolean contains(String fieldName) {
        return true;
    }
    
    override public Object get(String fieldName) {
		return DateTime.now();
    }
}
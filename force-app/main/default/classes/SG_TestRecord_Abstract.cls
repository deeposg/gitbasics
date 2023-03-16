public abstract class SG_TestRecord_Abstract {
    public String errMsg = '';

    abstract public boolean contains(String fieldName);
    abstract public Object get(String fieldName);
    
    public void addError(String errMsg) {
		this.errMsg = errMsg;
    }
}
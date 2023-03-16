export default function generateData({ amountOfRecords }) {
    return [...Array(amountOfRecords)].map((_, index) => {
        const attachment_count =  Math.random() < 0.5 ? 1 : 0;
        const delivery_result =  Math.random() < 0.3 ? 'Bounced' : 'Delivered';

        return {
            id:"msg_" + index,
            from: 'OSG Sales\nsales@osg.ca',
            recipient: 'Greg Thomson\nthomsong@gmail.com',
            subject: `Long subject goes here Long subject goes here Long subject goes here (${index})`,
            attachment_icon: attachment_count > 0 ? 'utility:attach' : null,
            delivery_result,
            status_class:delivery_result === 'Bounced' ? 'slds-text-color_error' : '',
            send_date: new Date(
                Date.now() + 86400000 * Math.ceil(Math.random() * 20)
            ),
        };
    });
}
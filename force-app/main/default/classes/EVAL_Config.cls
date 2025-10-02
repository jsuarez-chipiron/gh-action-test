/**
 * @description Constants for EVAL module
 */
public class EVAL_Config {

    /**
     * @description Email body template for sending AI metrics.
     * Placeholders:
     * {0}: Case Number
     * {1}: Is Spam (Boolean)
     * {2}: Spam Accuracy (%)
     * {3}: Spam Reason
     */
    public static final String AI_METRICS_EMAIL_BODY_TEMPLATE = 
        'Las métricas de Inteligencia Artificial para el Caso {0} han sido procesadas.\n\n' +
        'Resultado SPAM:\n' +
        '- Es Spam: {1}\n' +
        '- Precisión del modelo de Spam: {2}%\n' +
        '- Motivo: {3}\n\n' +
        'Resultado LANG:\n' +
        '- Lenguaje: {4}\n' +
        '- Precisión del modelo de Lenguaje: {6}%\n' +
        '- Motivo: {5}\n\n' +
        'Gracias.';
}
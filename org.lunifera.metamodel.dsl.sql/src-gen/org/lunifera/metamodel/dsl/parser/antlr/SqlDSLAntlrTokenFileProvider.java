/*
* generated by Xtext
*/
package org.lunifera.metamodel.dsl.parser.antlr;

import java.io.InputStream;
import org.eclipse.xtext.parser.antlr.IAntlrTokenFileProvider;

public class SqlDSLAntlrTokenFileProvider implements IAntlrTokenFileProvider {
	
	public InputStream getAntlrTokenFile() {
		ClassLoader classLoader = getClass().getClassLoader();
    	return classLoader.getResourceAsStream("org/lunifera/metamodel/dsl/parser/antlr/internal/InternalSqlDSL.tokens");
	}
}

/**
 * Copyright (c) 2011 - 2012, Florian Pirchner - lunifera.org
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 * 
 * Sources generated by Xtext
 * 
 * Contributors:
 * 		Florian Pirchner - Initial implementation
 */
package org.lunifera.metamodel.dsl.generator

import com.google.inject.Inject
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.IFileSystemAccess
import org.eclipse.xtext.generator.IGenerator
import org.eclipse.xtext.xbase.lib.IterableExtensions
import org.lunifera.metamodel.dsl.sqlDSL.SModel
import org.lunifera.metamodel.dsl.sqlDSL.SSettings
import org.lunifera.metamodel.dsl.sqlDSL.STable
import org.lunifera.metamodel.dsl.sqlDSL.SColumn
import org.lunifera.metamodel.dsl.sqlDSL.SJoinColumn

class SqlDSLGenerator implements IGenerator {
	
	@Inject extension IterableExtensions
	@Inject extension HelperExtensions
	
	private int indexLeft
	
	override void doGenerate(Resource resource, IFileSystemAccess fsa) {
		for(model : resource.allContents.filter(typeof(SModel)).toIterable){
		var String generatedFile =	model.generatedFile;
			fsa.generateFile(generatedFile.concat(".sql"), model.generate);
		}
	}
	
	def dispatch generate(SModel model)'''
		-- schema --
		«model.settings.generateSchema»
		
		«FOR table : model.artifact.filter(typeof(STable))»
		«table.generate»
		«ENDFOR»
		
		«FOR table : model.artifact.filter(typeof(STable)).filter([it.shouldGenerateForeignKey])»
		«table.generateForeignKey»
		«ENDFOR»
	'''
		
	def generateSchema(SSettings settings)'''
		CREATE SCHEMA IF NOT EXISTS «settings.toDBSchemaString» CHARACTER SET = utf8;
	'''
	
	def dispatch generate(STable  table)'''
		«table.initIndexCounter»
		«table.toComment»
		CREATE TABLE «table.toDBSchemaString».«table.toDBTableString»(
			«table.toColumnPrefix»_ID int NOT NULL AUTO_INCREMENT COMMENT 'id',
			«FOR column : table.columns»
			«column.generate»
			«ENDFOR»
			«table.toColumnPrefix»_CREATED_BY int NOT NULL COMMENT 'createdBy',
			«table.toColumnPrefix»_CREATED_AT datetime NOT NULL COMMENT 'createdAt',
			«table.toColumnPrefix»_CHANGED_BY int NOT NULL COMMENT 'changedAt',
			«table.toColumnPrefix»_CHANGED_AT datetime NOT NULL COMMENT 'changedAt',
			«table.toColumnPrefix»_VERSION mediumint NOT NULL COMMENT 'version',
			
			PRIMARY KEY (MDE_ID),
			KEY MDE_ID (MDE_ID)«IF indexLeft()»,«ENDIF»
			«FOR column : table.columns.filter([it.isIndexed])»
			«column.generateIndex»«decreaseIndexCounter»«IF indexLeft()»,«ENDIF»
			«ENDFOR»
		) ENGINE = «table.toDBEngineString» DEFAULT CHARSET = utf8;
	'''
	
	def void initIndexCounter(STable table){
		indexLeft = table.columns.filter([it.isIndexed]).size
	}
	
	def void decreaseIndexCounter(){
		indexLeft = indexLeft - 1;
	}
	
	def boolean indexLeft(){
		return indexLeft > 0
	}
	
	def dispatch generate(SColumn  column)'''
		«column.toColumnName» «column.toColumnType» «column.toNullableModifier»«column.toAESModifier»«column.toComment», «column.finishColumn»'''
	
	def dispatch generate(SJoinColumn  column)'''
		«column.toColumnName»«column.toColumnType»«column.toNullableModifier»«column.toAESModifier»«column.toComment»,'''
		
	def dispatch generateIndex(SColumn column)'''
		«column.toIndexType» KEY IDX_«column.toColumnName» («column.toColumnName»)'''
		
	def dispatch generateIndex(SJoinColumn  column)'''
		KEY IDX_«column.toColumnName» («column.toColumnName»)'''

	def generateForeignKey(STable table){
		var StringBuilder builder = new StringBuilder
		for(joinColumn : table.columns.filter(typeof(SJoinColumn))){
			var STable referencedTable = joinColumn.referencedType
			builder.append(table.generateForeignKey(referencedTable)).append("\n");
		}
		return builder.toString
	}

	def generateForeignKey(STable table, STable refTable)'''
		ALTER TABLE «table.toDBSchemaString».«table.toDBTableString»
			ADD CONSTRAINT FK_«table.toColumnPrefix»_«refTable.toColumnPrefix»_ID FOREIGN KEY («table.toColumnPrefix»_«refTable.toColumnPrefix»_ID)
			REFERENCES «refTable.toDBSchemaString».«refTable.toDBTableString»(«refTable.toColumnPrefix»_ID)
	'''
}

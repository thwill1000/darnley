using System;
using System.IO;
using System.Text;
using System.Xml;

namespace DarnleyDatabaseConverter
{
	/// <summary>
	/// Class to convert the PSION OPL .dbf database for the 'Sealed Room Murder'.
	/// </summary>
	class DarnleyDatabaseConverter
	{
		const string USAGE = "Usage: DarnleyDatabaseConverter.exe <filename.dbf>";
		const string APPNAME = "DarnleyDatabaseConverter";
		const string DASHES_80 = "--------------------------------------------------------------------------------";

		/// <summary>
		/// The main entry point for the application.
		/// </summary>
		[STAThread]
		static void Main(string[] args)
		{
			Console.WriteLine(APPNAME + " starting...");

			if (args.Length != 1) 
			{
				FatalError("incorrect number of arguments.");
			}

			string inFileName = args[0];
			Console.WriteLine("Reading file: " + inFileName);
			if (inFileName.Length < 5 ||
				inFileName.Substring(inFileName.Length - 4, 4).ToUpper() != ".DBF")
			{
				FatalError("incorrect file extension, expected .dbf file.");
			}
			
			if (!File.Exists(inFileName)) 
			{
				FatalError(inFileName + " does not exist.");
			}
			
			FileStream inStream = new FileStream(
				inFileName, FileMode.Open, FileAccess.Read);
			BinaryReader inReader = new BinaryReader(inStream);

			byte[] signatureBytes = inReader.ReadBytes(16);
			string signature = "";
			for (int i = 0; i < signatureBytes.Length; i++) 
			{
				signature += (char)signatureBytes[i];
			}
			short  dbfVersion = inReader.ReadInt16();
			short  headerSize = inReader.ReadInt16();
			short  dbfVersion2 = inReader.ReadInt16();
			byte[] extendedHeader = inReader.ReadBytes(headerSize - 22);

			Console.WriteLine(DASHES_80);
			Console.WriteLine("signature:   " + signature);
			Console.WriteLine("dbfVersion:  " + dbfVersion);
			Console.WriteLine("headerSize:  " + headerSize);
			Console.WriteLine("dbfVersion2: " + dbfVersion2);
			Console.WriteLine(DASHES_80);
			
			//
			// Validate first record - the field information record.
			//
			if (true) {
				int recordHeader = inReader.ReadInt16();
				int dataSize = recordHeader & 0x0FFF;
				int type = recordHeader & 0xF000;
				byte[] data = inReader.ReadBytes(dataSize);
				
				Console.WriteLine("Field information record:");
				for (int i = 0; i < data.Length; i++) 
				{
					string fieldType = "";
					switch (data[i]) 
					{
						case 0: fieldType = "word"; break;
						case 1: fieldType = "long"; break;
						case 2: fieldType = "real"; break;
						case 3: fieldType = "qstr (string)"; break;
						default: fieldType = "<unknown>"; break;
					}
					Console.WriteLine("Field[{0}] type = {1}", i, fieldType);
				}
				Console.WriteLine(DASHES_80);
			}

			string outFileName = inFileName.Substring(0, inFileName.Length - 3) + "xml";
			Console.WriteLine("Writing file: " + outFileName);
			XmlWriter outWriter = new XmlTextWriter(outFileName, System.Text.Encoding.ASCII);
			outWriter.WriteStartDocument(true);
			outWriter.WriteStartElement("darnley");

			int counter = 1;
			try 
			{
				for (;;) 
				{
					ReadRecord(inReader, ref counter, outWriter);
/*
					if (type != 1) 
					{
						Environment.Exit(-1);
					}
*/					
				}
			}
			catch (IOException ex) 
			{
			}

			outWriter.WriteEndElement();
			outWriter.WriteEndDocument();
			outWriter.Close();
			inReader.Close();
			inStream.Close();
			
			Console.WriteLine(APPNAME + " finished.");
		}

		/// <summary>
		/// Called in the event of a fatal error. Dumps the USAGE information
		/// to stdout and terminates the application.
		/// </summary>
		private static void FatalError(string err) 
		{
			Console.WriteLine("ERROR: " + err);
			Console.WriteLine(USAGE);
			Console.WriteLine(APPNAME + " finished.");
			Environment.Exit(-1);
		}

		class Record 
		{
			private int m_ID;
			private string m_Name;
			private string m_Code1;
			private string m_Code2;
			private string m_Text;

			public int ID
			{
				get 
				{
					return m_ID;
				}
				set 
				{
					m_ID = value;
				}
			}

			public string Name
			{
				get 
				{
					return m_Name;
				}
				set 
				{
					m_Name = value;
				}
			}

			public string Code1
			{
				get 
				{
					return m_Code1;
				}
				set 
				{
					m_Code1 = value;
				}
			}

			public string Code2
			{
				get 
				{
					return m_Code2;
				}
				set 
				{
					m_Code2 = value;
				}
			}

			public string Text
			{
				get 
				{
					return m_Text;
				}
				set 
				{
					m_Text = value;
				}
			}
		} // class Record

		static Record ReadRecord(BinaryReader inReader, int size) 
		{
			Record r = new Record();
			StringBuilder sb = new StringBuilder();
			int bytesRead = 0;
			for (int field = 0; field < 22 && bytesRead < size; field++) 
			{
				byte length = inReader.ReadByte();
				bytesRead += 1;
				char[] s = inReader.ReadChars(length);
				bytesRead += length;
				string txt = new String(s);

				switch (field) 
				{
					case 0:
						r.ID = Int32.Parse(txt);
						break;
					case 1:
						r.Name = txt;
						break;
					case 2:
						if (txt != "~") 
						{
							r.Code1 = txt;
						}
						break;
					case 3:
						if (txt != "~") 
						{
							r.Code2 = txt;
						}
						break;
					default:
						if (txt.Length != 0) 
						{
							if (sb.Length != 0) 
							{
								sb.Append("\n");
							}
							sb.Append(txt);
						}
						break;
				}
			}

			r.Text = sb.ToString();

			return r;
		}

		static void ReadRecord(BinaryReader inReader, ref int recordNo, XmlWriter outWriter) // throws IOException
		{
			int recordHeader = inReader.ReadInt16();
			int dataSize = recordHeader & 0x0FFF;
			int type = recordHeader & 0xF000;
			type >>= 12;
			Console.WriteLine("Record " + recordNo + ":");
			Console.WriteLine("Type: " + type);
			Console.WriteLine("Size: " + dataSize);

			if (type == 1) 
			{
				Record r = ReadRecord(inReader, dataSize);
/*
				Console.WriteLine("ID    = {0}", r.ID);
				Console.WriteLine("Name  = {0}", r.Name);
				Console.WriteLine("Code1 = {0}", r.Code1);
				Console.WriteLine("Code2 = {0}", r.Code2);
				Console.WriteLine("Text  = {0}", r.Text);
*/				
				string tag = "record";
				if (r.ID < 100) 
				{
					tag = "location";
				}
				else if (r.ID < 200) 
				{
					tag = "person";
				}
				else if (r.ID < 300) 
				{
					tag = "item";
				}
				else if (r.ID > 1000) 
				{
					tag = "interrogation";
				}

				outWriter.WriteStartElement(tag);
				outWriter.WriteAttributeString("id", "" + r.ID);
				outWriter.WriteAttributeString("name", r.Name);
				outWriter.WriteAttributeString("code1", r.Code1);
				outWriter.WriteAttributeString("code2", r.Code2);
				outWriter.WriteRaw("\n");
				outWriter.WriteElementString("text", r.Text);
				outWriter.WriteRaw("\n");
				outWriter.WriteEndElement();
				outWriter.WriteRaw("\n");
			}
			else 
			{
				inReader.ReadBytes(dataSize);
			}
			
			Console.WriteLine(DASHES_80);
			recordNo++;
		}
	}
}

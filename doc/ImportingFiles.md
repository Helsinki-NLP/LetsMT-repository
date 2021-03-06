
# Importing files to the repository

The LetsMT! repository backend can be used to collect, convert and align a variety of different kind of document formats. The main principle is that documents are uploaded in their native format and the backend takes care of the extraction of the textual content and the alignment between translated documents. Most things should run automagically but the import process can still be [influenced and configured](ImportConfiguration.md) in various ways.

There is basically two parts in each branch of a storage slot: the `upload` section and the `xml` section. `uploads` contains the files that are uploaded by the user and it should be organised by data format and language. Here is an example:

```
Slot (git repository)
├ branch (user's copy of data)
│  ├ uploads
│  │ ├ doc
│  │ │  ├ de
│  │ │  │ └ word.doc
│  │ │  ├ en
│  │ │  │ └ word.doc
│  │ │  └ fr
│  │ │    └ word.doc
│  │ ├ tmx
│  │ │  ├ first.tmx
│  │ │  └ second.tmx
│  │ └ pdf
│  │    └ ...
```

LetsMT! includes language detection software but it is good practice to organise files in separate sub-directories that specify the language of the document content (see the Word documents in `uploads/doc`). Files with the same name and paths except the language-related sub-directory will be aligned automatically, for example the files called `word.doc` in the example above.

There are some further built-in heuristics to match potentially parallel documents but one should not rely too much on those and rather go for a clean data structure.

Imported files are converted to standalone XML and will be stored in the `xml` sub-directory of the storage branch. The paths and names typically correspond to the name of the upload files:


```
Slot (git repository)
├ branch (user's copy of data)
│  ├ uploads
│  ├ xml
│  │ ├ de
│  │ │ └ word.xml
│  │ ├ en
│  │ │ └ word.xml
│  │ └ fr
│  │   └ word.xml
```

Sentence alignments are produced for every combination of languages (in alphabetical order) and stored in sub-directories under `xml`. File names correspond to the aligned files.

```
Slot (git repository)
├ branch (user's copy of data)
│  ├ uploads
│  ├ xml
│  │ ├ de-en
│  │ │    └ word.xml
│  │ ├ de-fr
│  │ │    └ word.xml
│  │ ├ en-fr
│  │ │    └ word.xml
```

The import can be triggered directly when uploading the file or started later using the `job` API. LetsMT! also supports the upload of zip and tar archives. Files in those archives should then also be organised according to the upload structure above with path names relative to the upload directory.

Importing files and the automatic alignment can be configured in various ways. There is a separate page about [configurations of import and alignment](ImportConfiguration.md).

Examples for importing files via the backend APIs are given further down.


# Supported upload formats


File archives:

* tar
* tar.gz
* zip

Aligned parallel data:

* TMX
* XLIFF
* Moses

Other data formats:

* TXT (in various character encodings)
* PDF
* doc, docx
* XML
* HTML
* RTF
* ODF
* iWorks
* WordPerfect
* EPUB


# Web crawling

The latest version of the repository backend also supports (expermental) web crawling from given websites. The system downloads all files and stores them in the repository as a tar-archive. A crawling job can be submitted via the job API and the `run=crawl` command:

```
$LETSMT_CONNECT -X PUT "$LETSMT_URL/job/corpus/user/crawl?uid=user&action=import&url=https://www.helsinki.fi&run=crawl"
```

 The additional command in `action` above tiggers the automatic import of the tar-file after web crawling is done (this is optional).

It may be useful to set the search for translated documents to `similar-names` (instead of `identical-names`, which is the default). This would improve the matching of potentially translated documents (but it can also cause a lot of trouble):

```
$LETSMT_CONNECT -X POST "$LETSMT_URL/metadata/www.helsinki.fi/user?uid=user&AlignPara_search_parallel=similar-names"
``` 

There are also two useful parameters that change the behaviour of the crawler: `accept` and `reject`: Both of them can be used to restrict the file types that are kept when doenloading from the website. You can specify an arbitrary number of comma-separated file extensions to either reject certain file types (there is already a number of file types that are rejected by default and the parameter only adds additional types) or to ONLY accept certain file types. For example, to reject all PDF and DOC documents, add the parameter `reject=pdf,doc`

```
$LETSMT_CONNECT -X PUT "$LETSMT_URL/job/corpus/user/crawl?uid=user&action=import&url=https://www.helsinki.fi&run=crawl&reject=pdf,doc"
```

To download only pdf and doc files you can do:

```
$LETSMT_CONNECT -X PUT "$LETSMT_URL/job/corpus/user/crawl?uid=user&action=import&url=https://www.helsinki.fi&run=crawl&accept=pdf,doc"
```




# Examples of file imports


* set up a storage slot

```
$LETSMT_CONNECT -X POST "$LETSMT_URL/group/user1/user1?uid=user1"
$LETSMT_CONNECT -X PUT "$LETSMT_URL/storage/slot1/user1?uid=user1&gid=user1"
```

* upload a pdf document

```
$LETSMT_CONNECT -X PUT "$LETSMT_URL/storage/slot1/user1/uploads/pdf/D2.1.pdf?uid=user1" --form payload=@D2.1.pdf 
$LETSMT_CONNECT -X GET "$LETSMT_URL/storage/slot1/user1/uploads/pdf?uid=user1"
```
```xml
<letsmt-ws version="55">
  <list path="/slot1/user1/uploads/pdf">
    <entry kind="file">
      <name>D2.1.pdf</name>
      <commit revision="HEAD">
        <author>user1</author>
        <date>unknown</date>
      </commit>
      <group>user1</group>
      <owner>user1</owner>
      <size>288515</size>
    </entry>
  </list>
  <status code="0" location="/storage/slot1/user1/uploads/pdf" operation="GET" type="ok"></status>
</letsmt-ws>
```

* submit an import job for that file

```
$LETSMT_CONNECT -X PUT "$LETSMT_URL/job/slot1/user1/uploads/pdf/D2.1.pdf?uid=user1&run=import"
```
```xml
<letsmt-ws version="55">
  <status code="0" location="/job/slot1/user1/uploads/pdf/D2.1.pdf" operation="PUT" type="ok">job maker submitted (storage/slot1/user1/jobs/run/uploads/pdf/D2.1.pdf.import)</status>
</letsmt-ws>
```


* metadata stores the status and result of the import job:

```
$LETSMT_CONNECT -X GET "$LETSMT_URL/metadata/slot1/user1/uploads/pdf/D2.1.pdf?uid=user1"
```
```xml
<letsmt-ws version="55">
  <list path="">
    <entry path="slot1/user1/uploads/pdf/D2.1.pdf">
      <gid>user1</gid>
      <import_runtime>18</import_runtime>
      <imported_to>xml/en/D2.1.xml</imported_to>
      <job_id>job_1536340573_54158800</job_id>
      <job_log_err>/var/log/letsmt/batch_jobs/job_1536340573_54158800.e</job_log_err>
      <job_log_out>/var/log/letsmt/batch_jobs/job_1536340573_54158800.o</job_log_out>
      <job_status>submitted to grid engine with status: running</job_status>
      <owner>user1</owner>
      <status>imported</status>
    </entry>
  </list>
  <status code="0" location="/metadata/slot1/user1/uploads/pdf/D2.1.pdf" operation="GET" type="ok">Found matching path ID. Listing all of its properties</status>
</letsmt-ws>
```


* once the status changed to `imported` you should see the XML file it was converted into:

```
$LETSMT_CONNECT -X GET "$LETSMT_URL/storage/slot1/user1/xml/en/D2.1.xml?uid=user1"
```
```xml
<letsmt-ws version="55">
  <list path="/slot1/user1/xml/en/D2.1.xml">
    <entry kind="file">
      <name>D2.1.xml</name>
      <commit revision="HEAD">
        <author>user1</author>
        <date>unknown</date>
      </commit>
      <group>user1</group>
      <owner>user1</owner>
      <size>77762</size>
    </entry>
  </list>
  <status code="0" location="/storage/slot1/user1/xml/en/D2.1.xml" operation="GET" type="ok"></status>
</letsmt-ws>
```

Note that the language detector kicked in here and found out that the document is in English. Therefore, it is placed into `xml/en`.


* automatically trigger import after upload

add `action=import` to the upload request:

```
$LETSMT_CONNECT -X PUT "$LETSMT_URL/storage/slot1/user1/uploads/pdf/D2.1.pdf?uid=user1&action=import" --form payload=@D2.1.pdf 
```
```xml
<letsmt-ws version="55">
  <status code="0" location="/storage/slot1/user1/uploads/pdf/D2.1.pdf" operation="PUT" type="ok">update ok /slot1/user1/uploads/pdf/D2.1.pdf,submitted job with ID 'job_1536341031_541180703'</status>
</letsmt-ws>
```

* download websites from URLs: We can now specify a URL to download files directly from the web:

```
$LETSMT_CONNECT -X PUT "$LETSMT_URL/storage/mycorpus10/user/uploads/url/spiegel.de/index.html?uid=user&action=import&url=http://www.spiegel.de"
```

This can also be done via the job API to run a job in the backend (using slurm - no overhead of downloading directly during the storage request): use the additional command `run=download`:

```
$LETSMT_CONNECT -X PUT "$LETSMT_URL/job/corpus/user/uploads/url/de/spiegel.de/index.html?uid=user&action=import&url=http://www.spiegel.de&run=download"
```

You can also leave out the relative path to the upload dir and then the system will create a path from the URL that is relative to `uploads/url`

```
$LETSMT_CONNECT -X PUT "$LETSMT_URL/job/corpus/user&action=import&url=http://www.spiegel.de&run=download"
```

It removes special characters and the protocol of the URI. In the example above it creates a resource in `corpus/user/uploads/url/de/www.spiegel.de`.



* import queue

The metadata on branch level includes information about the import queue:

```
$LETSMT_CONNECT -X GET "$LETSMT_URL/metadata/slot1/user1?uid=user1"
```
```xml
<letsmt-ws version="55">
  <list path="">
    <entry path="slot1/user1">
      <name>user1</name>
      <acces>2018-09-06 18:28:56</acces>
      <create>2018-09-06 18:28:56</create>
      <gid>user1</gid>
      <import_queue>uploads/pdf/D2.1.pdf</import_queue>
      <langs>en</langs>
      <modif>2018-09-06 18:28:56</modif>
      <owner>user1</owner>
      <resource-type>branch</resource-type>
      <slot>slot1</slot>
      <status>updated</status>
      <uid>user1</uid>
    </entry>
  </list>
  <status code="0" location="/metadata/slot1/user1" operation="GET" type="ok">Found matching path ID. Listing all of its properties</status>
</letsmt-ws>
```


* the languages and language pairs covered in a branch are also listed in the metadata of the branch:

```
$LETSMT_CONNECT -X GET "$LETSMT_URL/metadata/corpus/user?uid=user1"
```
```xml
<letsmt-ws version="55">
  <list path="">
    <entry path="corpus/user">
      <name>user</name>
      <acces>2018-08-31 20:47:50</acces>
      <create>2018-08-31 20:47:50</create>
      <gid>public</gid>
      <import_queue></import_queue>
      <langs>fr,et,zh,en,ru,es,ar,sv,so,fa,tr,fi</langs>
      <modif>2018-08-31 20:47:50</modif>
      <owner>user</owner>
      <parallel-langs>ru-tr,ar-ru,fa-so,es-ru,fr-so,fa-zh,en-fa,so-sv,en-et,en-so,ar-fr,fi-so,ru-sv,en-fi,et-fa,es-fr,fa-tr,et-so,fr-ru,sv-tr,es-zh,sv-zh,en-sv,en-fr,et-fi,ar-en,et-zh,tr-zh,en-es,ar-fi,es-sv,es-fa,ar-sv,fa-fr,es-fi,so-tr,fr-sv,es-so,fi-sv,ru-so,fa-fi,en-tr,ar-zh,fi-zh,ar-so,ar-tr,ar-es,es-tr,fr-zh,fr-tr,fa-ru,ar-et,et-ru,ru-zh,en-zh,fi-fr,es-et,et-sv,et-fr,fi-tr,et-tr,fi-ru,en-ru,ar-fa,so-zh,fa-sv</parallel-langs>
      <resource-type>branch</resource-type>
      <slot>corpus</slot>
      <uid>user</uid>
    </entry>
  </list>
  <status code="0" location="/metadata/corpus/user" operation="GET" type="ok">Found matching path ID. Listing all of its properties</status>
</letsmt-ws>
```


* e-mail TMX files of all bitexts that come ot of an import

```
$LETSMT_CONNECT -X PUT "$LETSMT_URL/storage/corpus/user/uploads/archive.tar.gz?uid=user&action=import&email=name@domain.com" --form payload=@archive.tar.gz
```

NOTE: This sends one e-mail per document pair! This may become many e-mails if the arhive contains a lot of parallel documents!



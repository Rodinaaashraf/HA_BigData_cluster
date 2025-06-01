import happybase
import hashlib
import time
from faker import Faker

fake = Faker()
connection = happybase.Connection('localhost')
table = connection.table('webtable')

domains = ['example.com', 'test.org', 'sample.net', 'univ.edu', 'data.gov']
pages_per_domain = 4

def reverse_domain(domain):
    return '.'.join(reversed(domain.split('.')))

def reverse_timestamp(ts):
    return str((2**64 - 1) - ts)

def url_hash(url):
    return hashlib.sha1(url.encode()).hexdigest()[:8]

for domain in domains:
    for i in range(pages_per_domain):
        # Generate page data
        url = f"http://{domain}/page{i+1}"
        rev_domain = reverse_domain(domain)
        rev_ts = reverse_timestamp(int(time.time() * 1000))
        row_key = f"{rev_domain}|{url_hash(url)}|{rev_ts}"
        
        # Generate content of varying sizes
        if i % 3 == 0:
            content = fake.text(max_nb_chars=5000)  # Large
        elif i % 3 == 1:
            content = fake.text(max_nb_chars=1000)  # Medium
        else:
            content = fake.text(max_nb_chars=200)   # Small
            
        # Generate metadata
        status_code = 200 if i % 5 != 0 else 404  # Some error pages
        title = fake.sentence()
        
        # Generate links (simplified)
        outlinks = [f"http://{domain}/page{(i+j)%pages_per_domain+1}" for j in range(1,3)]
        inlinks = [f"http://{domains[(idx+1)%5]}/page{j+1}" for idx, d in enumerate(domains) for j in range(2)]
        
        # Put data into HBase
        table.put(row_key, {
            'content:html': content,
            'metadata:url': url,
            'metadata:title': title,
            'metadata:status': str(status_code),
            'metadata:size': str(len(content)),
            'metadata:created': str(int(time.time() * 1000)),
            **{f'outlinks:{link}': '1' for link in outlinks},
            **{f'inlinks:{link}': '1' for link in inlinks if link != url}
        })
        print(f"Inserted: {url}")

connection.close()

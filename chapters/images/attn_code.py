def forward(self, x):  # Sample PyTorch code for the multi-head attention calculation
    # Store batch size, sequence length, model dimension
    B, S, D = x.size() 

    # Calculate query, key, values for all heads in batch 
    # (B, S, D) x (D, 3D) -> (B, S, 3D) -> 3 separate (B, S, D)
    q, k, v  = self.c_attn(x).split(self.n_embd, dim=2) 

    # Split out and transpose head forward next to the batch dim
    # (B, S, D) -> (B, H, S, d_k) where d_k = D / H
    q = q.view(B, S, self.n_head, D // self.n_head).transpose(1, 2)
    k = k.view(B, S, self.n_head, D // self.n_head).transpose(1, 2)
    v = v.view(B, S, self.n_head, D // self.n_head).transpose(1, 2)

    # Calculate scores for self-attention
    # (B, H, S, d_k) x (B, H, d_k, S) -> (B, H, S, S)
    att = (q @ k.transpose(-2, -1)) * (1.0 / math.sqrt(k.size(-1)))

    # Causal mask and SoftMax
    # (B, H, S, S)
    att = att.masked_fill(self.bias[:,:,:S,:S] == 0, float('-inf'))
    att = F.softmax(att, dim=-1)

    # Combine values by attention weights
    # (B, H, S, S) x (B, H, S, d_k) -> (B, H, S, d_k)
    y = att @ v 

    # Re-assemble weighted values from all heads side by side
    # (B, H, S, d_k) -> (B, S, D)
    y = y.transpose(1, 2).contiguous().view(B, S, D) 

    # Output projection
    # (B, S, D) x (D, D) -> (B, S, D)
    y = self.resid_dropout(self.c_proj(y))
    return y
